# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::ProcessSubmissionJob, type: :job do
  let(:session_id) { SecureRandom.hex(16) }
  let(:args) do
    {
      session_answers: {causes: ["Education"], state: "TN"},
      user_type: "donor",
      session_id: session_id,
      user_id: nil
    }
  end

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    # Test env uses :null_store, which never persists; swap in a real store so
    # the processing/error flag semantics can be exercised.
    allow(Rails).to receive(:cache).and_return(memory_cache)
    Rails.cache.write(described_class.processing_key(session_id), true)
  end

  it "runs SubmissionProcessor and clears the processing flag on success" do
    expect(SmartMatch::SubmissionProcessor).to receive(:call).and_return({submission: build(:quiz_submission), results: []})

    described_class.perform_now(**args)

    expect(Rails.cache.exist?(described_class.processing_key(session_id))).to be(false)
    expect(Rails.cache.exist?(described_class.error_key(session_id))).to be(false)
  end

  it "is idempotent: skips work when a submission already exists for the session" do
    create(:quiz_submission, session_id: session_id)
    expect(SmartMatch::SubmissionProcessor).not_to receive(:call)

    described_class.perform_now(**args)
  end

  it "records a terminal error and clears the processing flag when embedding is unavailable" do
    allow(SmartMatch::SubmissionProcessor).to receive(:call)
      .and_raise(SmartMatch::EmbeddingUnavailableError)

    described_class.perform_now(**args)

    expect(Rails.cache.exist?(described_class.error_key(session_id))).to be(true)
    expect(Rails.cache.exist?(described_class.processing_key(session_id))).to be(false)
  end
end
