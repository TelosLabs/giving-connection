# frozen_string_literal: true

module SmartMatch
  EmbeddingUnavailableError = Class.new(StandardError)

  class EmbeddingClient < ApplicationService
    TIMEOUT = 120
    MAX_RETRIES = 1
    BATCH_LIMIT = 64

    attr_reader :text

    def initialize(text:)
      @text = text
    end

    def call
      response = self.class.send(:http_post, "/embed", {text: text})
      JSON.parse(response.body).fetch("vector")
    end

    def self.embed_batch(texts:)
      texts.each_slice(BATCH_LIMIT).flat_map do |batch|
        response = http_post("/embed_batch", {texts: batch})
        JSON.parse(response.body).fetch("vectors")
      end
    end

    class << self
      private

      def http_post(path, payload)
        uri = URI.join(service_url, path)
        request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
        request.body = payload.to_json

        retries = 0
        begin
          response = Net::HTTP.start(uri.host, uri.port, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
            http.request(request)
          end

          unless response.is_a?(Net::HTTPSuccess)
            raise EmbeddingUnavailableError, "Embedding service returned #{response.code}"
          end

          response
        rescue EmbeddingUnavailableError
          raise
        rescue Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET => e
          retries += 1
          retry if retries <= MAX_RETRIES
          raise EmbeddingUnavailableError, "Embedding service unavailable: #{e.message}"
        end
      end

      def service_url
        ENV.fetch("EMBEDDING_SERVICE_URL", "http://127.0.0.1:8000")
      end
    end
  end
end
