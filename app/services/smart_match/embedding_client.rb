# frozen_string_literal: true

require "openssl"

module SmartMatch
  # Raised when the embedding service is unavailable, times out, returns a
  # transient failure, or returns a malformed payload. Callers should treat
  # this as retryable; jobs use `retry_on` and the results controller renders
  # a graceful fallback.
  EmbeddingUnavailableError = Class.new(StandardError) unless const_defined?(:EmbeddingUnavailableError)

  # Raised for non-retryable failures the embedding pipeline cannot recover
  # from (validation errors, 4xx-shaped responses). Jobs `discard_on` this.
  PermanentError = Class.new(StandardError) unless const_defined?(:PermanentError)

  class EmbeddingClient < ApplicationService
    # Per-request timeout. Plan budgets 5s for embedding so quiz submission
    # stays interactive; total retry budget stays under ~10s with jittered backoff.
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5
    MAX_RETRIES = 2
    BASE_BACKOFF = 0.3
    BATCH_LIMIT = 64

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
        response = http_post("/embed_batch", {texts: batch})
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

      def http_post(path, payload)
        uri = URI.join(service_url, path)
        request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
        request.body = payload.to_json

        retries = 0
        begin
          response = http_connection.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise EmbeddingUnavailableError, "Embedding service returned #{response.code}"
          end

          response
        rescue EmbeddingUnavailableError
          raise
        rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET,
               Net::OpenTimeout, Net::ReadTimeout, IOError, EOFError => e
          reset_http_connection!
          retries += 1
          if retries <= MAX_RETRIES
            sleep(backoff_with_jitter(retries))
            retry
          end
          raise EmbeddingUnavailableError, "Embedding service unavailable: #{e.message}"
        end
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
        http.verify_mode = (uri.scheme == "https" ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE)
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
