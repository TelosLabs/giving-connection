# frozen_string_literal: true

module SmartMatch
  # Raised when the embedding service is unavailable, times out, returns a
  # transient failure, or returns a malformed payload. Callers should treat
  # this as retryable; jobs use `retry_on` and the results controller renders
  # a graceful fallback.
  class EmbeddingUnavailableError < StandardError; end
end
