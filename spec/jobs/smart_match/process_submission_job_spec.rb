# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::ProcessSubmissionJob, type: :job do
  let(:session_id) { SecureRandom.hex(16) }
  # Cache state and idempotency key on the attempt, not the browser session:
  # the session survives a retake, so session-keyed state made a second attempt
  # look like the first was still in flight and skipped its work entirely.
  let(:attempt_token) { SecureRandom.uuid }
  let(:args) do
    {
      session_answers: {causes: ["Education"], state: "TN"},
      user_type: "donor",
      session_id: session_id,
      attempt_token: attempt_token,
      user_id: nil
    }
  end

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    # Test env uses :null_store, which never persists; swap in a real store so
    # the processing/error flag semantics can be exercised.
    allow(Rails).to receive(:cache).and_return(memory_cache)
    Rails.cache.write(described_class.processing_key(attempt_token), true)
  end

  it "runs SubmissionProcessor and clears the processing flag on success" do
    expect(SmartMatch::SubmissionProcessor).to receive(:call).and_return({submission: build(:quiz_submission), results: []})

    described_class.perform_now(**args)

    expect(Rails.cache.exist?(described_class.processing_key(attempt_token))).to be(false)
    expect(Rails.cache.exist?(described_class.error_key(attempt_token))).to be(false)
  end

  it "is idempotent: skips work when a submission already exists for the attempt" do
    create(:quiz_submission, session_id: session_id, attempt_token: attempt_token)
    expect(SmartMatch::SubmissionProcessor).not_to receive(:call)

    described_class.perform_now(**args)
  end

  # The retake bug: a submission from an earlier attempt in the same browser
  # session must not suppress this one.
  it "still runs when the session has an earlier attempt's submission" do
    create(:quiz_submission, session_id: session_id, attempt_token: SecureRandom.uuid)
    expect(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_return({submission: build(:quiz_submission), results: []})

    described_class.perform_now(**args)
  end

  # An unexpected error used to escape uncaught: no error flag was written, so
  # the results page polled forever and settled on "taking longer than usual"
  # with no way out. Now the flag is recorded AND the error re-raised, so the
  # user gets an answer and Sidekiq still retries.
  it "records the error flag and re-raises for an unexpected failure" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_raise(ActiveModel::UnknownAttributeError.new(QuizSubmission.new, "nope"))

    expect { described_class.perform_now(**args) }.to raise_error(ActiveModel::UnknownAttributeError)

    expect(Rails.cache.exist?(described_class.error_key(attempt_token))).to be(true)
    expect(Rails.cache.exist?(described_class.processing_key(attempt_token))).to be(false)
  end

  # The cache claim in ResultsController#ensure_processing_enqueued is the
  # first line of defence against a double enqueue, but it lives outside
  # Postgres: if the cache store is down, two workers can both pass the
  # exists? guard above and both try to INSERT. The unique index on
  # quiz_submissions.attempt_token is what stops the duplicate landing, and
  # the loser has nothing to report -- the winner's submission and matches are
  # already committed.
  it "stays quiet when a concurrent run won the insert race for this attempt" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call) do
      create(:quiz_submission, session_id: session_id, attempt_token: attempt_token)
      raise ActiveRecord::RecordNotUnique, "duplicate key value violates unique constraint"
    end

    expect { described_class.perform_now(**args) }.not_to raise_error

    expect(Rails.cache.exist?(described_class.error_key(attempt_token))).to be(false)
    expect(Rails.cache.exist?(described_class.processing_key(attempt_token))).to be(false)
  end

  # organization_matches carries its own unique index. A violation from THAT
  # insert is a real failure and must not be waved through as a benign
  # duplicate attempt -- nothing was persisted for this token.
  it "still fails on a unique violation that left no submission behind" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_raise(ActiveRecord::RecordNotUnique, "idx_org_matches_on_submission_and_org")

    expect { described_class.perform_now(**args) }.to raise_error(ActiveRecord::RecordNotUnique)

    expect(Rails.cache.exist?(described_class.error_key(attempt_token))).to be(true)
    expect(Rails.cache.exist?(described_class.processing_key(attempt_token))).to be(false)
  end

  it "does not re-raise a known terminal error" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_raise(SmartMatch::EmbeddingUnavailableError)

    expect { described_class.perform_now(**args) }.not_to raise_error
  end

  it "records a terminal error and clears the processing flag when embedding is unavailable" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_raise(SmartMatch::EmbeddingUnavailableError)

    described_class.perform_now(**args)

    expect(Rails.cache.exist?(described_class.error_key(attempt_token))).to be(true)
    expect(Rails.cache.exist?(described_class.processing_key(attempt_token))).to be(false)
  end
end
