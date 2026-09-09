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

    # Keyed on the attempt, not the browser session: the session outlives a
    # retake, so session-keyed state made the second attempt look like the
    # first one was still in flight.
    def self.processing_key(attempt_token) = "#{PROCESSING_KEY_PREFIX}:#{attempt_token}"

    def self.error_key(attempt_token) = "#{ERROR_KEY_PREFIX}:#{attempt_token}"

    def perform(session_answers:, user_type:, session_id:, attempt_token:, user_id: nil)
      # Idempotency: a duplicate/racing enqueue (or a retry after the submission
      # already landed) must not create a second submission + match set.
      #
      # Scoped to the attempt. Scoping to session_id instead meant a user who
      # retook the quiz got no new submission at all -- the guard saw their
      # first attempt and returned, and the results page then showed those old
      # matches as if they were the new ones.
      return if QuizSubmission.exists?(attempt_token: attempt_token)

      SmartMatch::SubmissionProcessor.call(
        session_answers: session_answers.symbolize_keys,
        user_type: user_type,
        session_id: session_id,
        attempt_token: attempt_token,
        user: (User.find_by(id: user_id) if user_id)
      )
    rescue ActiveRecord::RecordNotUnique => e
      # Lost the INSERT race for this attempt: the unique index on
      # quiz_submissions.attempt_token rejected the second submission, which is
      # exactly what it is there for. The cache claim in
      # ResultsController#ensure_processing_enqueued normally prevents the race
      # from starting, but it lives outside Postgres and fails with the cache
      # store; this is the backstop. The winner committed the submission and
      # its matches, so there is nothing left to do and nothing to report --
      # an error flag here would show a failure page for an attempt that
      # actually succeeded.
      #
      # Only benign once the attempt is genuinely on disk. organization_matches
      # carries its own unique index, and a violation from THAT insert rolls the
      # whole transaction back, leaving nothing for this token: that is a real
      # failure and takes the same path as any other unexpected error.
      unless QuizSubmission.exists?(attempt_token: attempt_token)
        record_terminal_error(e, attempt_token)
        raise
      end

      Rails.logger.info(
        "[SmartMatch::ProcessSubmissionJob] attempt #{attempt_token} already persisted by a concurrent run"
      )
    rescue SmartMatch::EmbeddingUnavailableError, SmartMatch::PermanentError,
      PG::Error, ActiveRecord::RecordInvalid, Net::HTTPFatalError => e
      # Known-terminal: retrying will not help, so record the flag and stop.
      # The polling page shows the graceful "unavailable" state instead of
      # spinning; the client's "try again" clears the flag and re-enqueues.
      record_terminal_error(e, attempt_token)
    rescue => e
      # Anything unexpected -- a NoMethodError from a stale worker, an
      # UnknownAttributeError after a migration the worker hasn't picked up.
      #
      # These used to escape uncaught, which left no error flag, so the results
      # page polled forever and settled on "this is taking longer than usual"
      # with no way out. Record the flag so the user gets a real answer, then
      # re-raise so Sidekiq still retries and the failure stays visible in the
      # logs and the dashboard rather than being silently swallowed.
      #
      # A successful retry still wins: ResultsController#show checks for a
      # submission before it checks this flag.
      record_terminal_error(e, attempt_token)
      raise
    ensure
      Rails.cache.delete(self.class.processing_key(attempt_token))
    end

    private

    def record_terminal_error(error, attempt_token)
      Rails.logger.error("[SmartMatch::ProcessSubmissionJob] #{error.class}: #{error.message}")
      Rails.cache.write(self.class.error_key(attempt_token), true, expires_in: STATE_TTL)
    end
  end
end
