# frozen_string_literal: true

# Enforces the job idempotency key at the database level.
#
# attempt_token is what stops ProcessSubmissionJob from scoring the same quiz
# attempt twice (see AddAttemptTokenToQuizSubmissions). Today the real guard is
# an atomic `Rails.cache.write(..., unless_exist: true)` claim in
# ResultsController#ensure_processing_enqueued, backed by a second
# `QuizSubmission.exists?(attempt_token:)` check inside the job.
#
# Both live outside Postgres, so both fail together: if the cache store is
# unavailable, two workers can pass the exists? check before either INSERTs and
# the attempt ends up with two submissions -- the same failure mode the token
# was introduced to fix, just harder to spot. A unique index makes the loser of
# that race raise instead of silently duplicating.
#
# Shipped as its own migration rather than as an edit to the original: that one
# has already run on developer databases, so an in-place change would leave
# them agreeing with schema.rb while lacking the constraint.
#
# Pre-existing rows are unaffected -- they predate the column and hold NULL,
# and Postgres treats NULLs as distinct in a unique index.
class MakeQuizSubmissionAttemptTokenUnique < ActiveRecord::Migration[7.2]
  def change
    remove_index :quiz_submissions, :attempt_token
    add_index :quiz_submissions, :attempt_token, unique: true
  end
end
