# frozen_string_literal: true

# Identifies which *attempt* a submission belongs to, rather than which
# browser session.
#
# Everything used to key on session_id, which survives a retake -- the quiz
# reset clears the smart_match_* keys but not the Rails session itself. That
# broke retaking in three compounding ways:
#
#   1. ProcessSubmissionJob's idempotency guard
#      (`return if QuizSubmission.exists?(session_id:)`) made the second
#      attempt a no-op, so it never produced a submission at all.
#   2. ResultsController#find_submission fell back to the newest submission
#      for the session and pinned it, so the previous attempt's results were
#      rendered as if they were the new ones.
#   3. #submission_present? reported "ready" immediately for the same reason,
#      so the page never even showed the processing state.
#
# The visible symptom was a user answering as a senior needing adult day care
# and being shown housing and mental-health matches from an earlier run.
#
# Nullable: submissions created before this shipped have no attempt.
class AddAttemptTokenToQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :quiz_submissions, :attempt_token, :string
    add_index :quiz_submissions, :attempt_token
  end
end
