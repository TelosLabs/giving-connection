# frozen_string_literal: true

module SmartMatch
  # Runs the (potentially slow) embedding + similarity + scoring pipeline off the
  # web request thread so a slow/degraded embedding service can never block Puma.
  # The results page enqueues this job and then polls the status endpoint until a
  # QuizSubmission (with its matches) has been persisted, or an error is recorded.
  class ProcessSubmissionJob < ApplicationJob
    queue_as :default

    PROCESSING_KEY_PREFIX = "smart_match:processing"
    ERROR_KEY_PREFIX = "smart_match:error"
    STATE_TTL = 10.minutes

    def self.processing_key(session_id) = "#{PROCESSING_KEY_PREFIX}:#{session_id}"

    def self.error_key(session_id) = "#{ERROR_KEY_PREFIX}:#{session_id}"

    def perform(session_answers:, user_type:, session_id:, user_id: nil)
      # Idempotency: a duplicate/racing enqueue (or a retry after the submission
      # already landed) must not create a second submission + match set.
      return if QuizSubmission.exists?(session_id: session_id)

      SmartMatch::SubmissionProcessor.call(
        session_answers: session_answers.symbolize_keys,
        user_type: user_type,
        session_id: session_id,
        user: (User.find_by(id: user_id) if user_id)
      )
    rescue SmartMatch::EmbeddingUnavailableError, SmartMatch::PermanentError,
      PG::Error, ActiveRecord::RecordInvalid, Net::HTTPFatalError => e
      # Record a terminal error so the polling page can show the graceful
      # "unavailable" state instead of spinning forever. The client's "try
      # again" clears this flag and re-enqueues.
      Rails.logger.error("[SmartMatch::ProcessSubmissionJob] #{e.class}: #{e.message}")
      Rails.cache.write(self.class.error_key(session_id), true, expires_in: STATE_TTL)
    ensure
      Rails.cache.delete(self.class.processing_key(session_id))
    end
  end
end
