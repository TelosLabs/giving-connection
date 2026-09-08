# frozen_string_literal: true

require "openssl"

module SmartMatch
  class EmbeddingClient < ApplicationService
    # Per-request timeout. Plan budgets 5s for embedding so quiz submission
    # stays interactive; total retry budget stays under ~10s with jittered backoff.
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5
    # Batch calls (EmbedAllOrganizationsJob) embed up to BATCH_LIMIT texts in a
    # single request against the CPU model, which routinely takes far longer
    # than the 5s interactive budget. They run off the request path, so they get
    # a much larger read timeout; without it Net::ReadTimeout trips the job's
    # retry_on and restarts the whole find_in_batches scope.
    BATCH_READ_TIMEOUT = 60
    MAX_RETRIES = 2
    BASE_BACKOFF = 0.3
    BATCH_LIMIT = 64

    # --- Circuit breaker -----------------------------------------------------
    # A slow or erroring embedding service can pin Puma threads: each
    # request-path call can cost up to MAX_RETRIES x READ_TIMEOUT plus backoff.
    # After CIRCUIT_FAILURE_THRESHOLD failures within CIRCUIT_WINDOW we "open"
    # the breaker and fail fast for CIRCUIT_COOLDOWN seconds -- raising
    # EmbeddingUnavailableError without touching the network -- so the graceful
    # "temporarily unavailable" page shows immediately instead of threads
    # piling up. After the cooldown the breaker half-opens: the next call is
    # allowed through; a success resets the breaker, a failure re-opens it.
    # State lives in Rails.cache (same store EmbedOrganizationJob.coalesce_for
    # already relies on); a null_store simply disables the breaker.
    CIRCUIT_FAILURE_THRESHOLD = 5
    CIRCUIT_WINDOW = 60 # seconds to accumulate failures
    CIRCUIT_COOLDOWN = 30 # seconds the breaker stays open
    CIRCUIT_FAILURE_KEY = "smart_match:embedding:failure_count"
    CIRCUIT_OPEN_KEY = "smart_match:embedding:open_until"

    # 4xx statuses that will fail identically on retry (malformed / invalid
    # request). These are raised as PermanentError so jobs discard rather than
    # burn their retry budget. Other 4xx that can succeed later (e.g. 408
    # Request Timeout, 429 Too Many Requests) stay transient.
    NON_RETRYABLE_STATUSES = [400, 422].freeze

    attr_reader :text

    def initialize(text:)
      @text = text
    end

    def call
      response = self.class.send(:http_post, "/embed", {text: text})
      self.class.parse_vector(response.body, key: "vector")
    end

    def self.embed_batch(texts:)
      texts.each_slice(BATCH_LIMIT).flat_map do |batch|
        response = http_post("/embed_batch", {texts: batch}, read_timeout: BATCH_READ_TIMEOUT)
        parse_vector(response.body, key: "vectors")
      end
    end

    class << self
      def parse_vector(body, key:)
        JSON.parse(body).fetch(key)
      rescue JSON::ParserError => e
        raise EmbeddingUnavailableError, "Embedding service returned invalid JSON: #{e.message}"
      rescue KeyError => e
        raise EmbeddingUnavailableError, "Embedding service response missing #{key}: #{e.message}"
      end

      private

      THREAD_CONN_KEY = :smart_match_embedding_http

      def http_post(path, payload, read_timeout: READ_TIMEOUT)
        # Fail fast while the breaker is open: don't touch the network and don't
        # count this as a failure (it isn't a real attempt).
        if circuit_open?
          raise EmbeddingUnavailableError, "Embedding service unavailable: circuit breaker open"
        end

        uri = URI.join(service_url, path)
        request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
        request.body = payload.to_json

        retries = 0
        begin
          conn = http_connection
          conn.read_timeout = read_timeout
          response = conn.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            if NON_RETRYABLE_STATUSES.include?(response.code.to_i)
              # Client-side/malformed request: a service bug, not an outage --
              # don't let it trip the breaker.
              raise PermanentError, "Embedding service rejected request: #{response.code}"
            end
            record_circuit_failure
            raise EmbeddingUnavailableError, "Embedding service returned #{response.code}"
          end

          record_circuit_success
          response
        rescue EmbeddingUnavailableError, PermanentError
          raise
        rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, IOError => e
          reset_http_connection!
          retries += 1
          if retries <= MAX_RETRIES
            sleep(backoff_with_jitter(retries))
            retry
          end
          record_circuit_failure
          raise EmbeddingUnavailableError, "Embedding service unavailable: #{e.message}"
        end
      end

      # Breaker is open while the open-marker key is present in the cache; it
      # self-clears when the key expires after CIRCUIT_COOLDOWN (half-open).
      def circuit_open?
        Rails.cache.read(CIRCUIT_OPEN_KEY).present?
      end

      # A success closes the breaker and clears the failure tally.
      def record_circuit_success
        Rails.cache.delete(CIRCUIT_FAILURE_KEY)
        Rails.cache.delete(CIRCUIT_OPEN_KEY)
      end

      # Count consecutive failures within a rolling window; open the breaker
      # once the threshold is reached. Read+write (rather than #increment) keeps
      # this correct across cache stores that don't support atomic increment.
      def record_circuit_failure
        count = (Rails.cache.read(CIRCUIT_FAILURE_KEY) || 0) + 1
        Rails.cache.write(CIRCUIT_FAILURE_KEY, count, expires_in: CIRCUIT_WINDOW)
        return if count < CIRCUIT_FAILURE_THRESHOLD

        Rails.cache.write(CIRCUIT_OPEN_KEY, true, expires_in: CIRCUIT_COOLDOWN)
      end

      # Per-thread keep-alive connection. Net::HTTP itself is not thread-safe,
      # so each Puma worker thread maintains its own started connection,
      # reused across requests until a connection-level error trips
      # reset_http_connection!.
      def http_connection
        conn = Thread.current[THREAD_CONN_KEY]
        return conn if conn&.started?

        uri = URI(service_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = ((uri.scheme == "https") ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE)
        http.keep_alive_timeout = 30
        http.start
        Thread.current[THREAD_CONN_KEY] = http
      end

      def reset_http_connection!
        http = Thread.current[THREAD_CONN_KEY]
        return unless http

        begin
          http.finish if http.started?
        rescue IOError
          # connection already closed by peer; ignore
        end
        Thread.current[THREAD_CONN_KEY] = nil
      end

      def backoff_with_jitter(attempt)
        # Exponential backoff with full jitter; capped so total retry budget
        # stays under ~10s (e.g. attempt 1: 0..0.6s, attempt 2: 0..1.2s).
        max = BASE_BACKOFF * (2**attempt)
        rand * max
      end

      def service_url
        ENV.fetch("EMBEDDING_SERVICE_URL", "http://127.0.0.1:8000")
      end
    end
  end
end
