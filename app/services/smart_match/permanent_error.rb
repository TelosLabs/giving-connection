# frozen_string_literal: true

module SmartMatch
  # Raised for non-retryable failures the embedding pipeline cannot recover
  # from (validation errors, 4xx-shaped responses). Jobs `discard_on` this.
  class PermanentError < StandardError; end
end
