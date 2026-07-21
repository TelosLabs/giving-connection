# frozen_string_literal: true

require "rails_helper"

# Covers the asynchronous results flow: the results GET enqueues
# SmartMatch::ProcessSubmissionJob (so the embedding + scoring pipeline never
# runs on the web thread) and renders a loading state that polls #status until
# matches land or a terminal error is recorded.
RSpec.describe "SmartMatch::Results async flow", type: :request do
  include ActiveJob::TestHelper

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    # Test env uses :null_store; the controller and job coordinate through the
    # cache (processing/error flags), so swap in a real store shared by both.
    allow(Rails).to receive(:cache).and_return(memory_cache)
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
  end

  # Drive the minimum session state that makes quiz_completed? true
  # (user_type + causes). Full navigation is covered by quizzes_flow_spec.
  def complete_minimum_quiz
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: %w[Education]}
  end

  describe "GET /smart_match/result with no submission yet" do
    before { complete_minimum_quiz }

    it "enqueues the match job and renders the loading state" do
      expect { get smart_match_result_path }
        .to have_enqueued_job(SmartMatch::ProcessSubmissionJob)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.results.processing.title"))
    end

    it "enqueues exactly one job across repeated loads/polls" do
      get smart_match_result_path

      expect {
        get smart_match_result_path
        get smart_match_result_path
      }.not_to change { enqueued_jobs.size }
    end
  end

  describe "GET /smart_match/result/status" do
    before { complete_minimum_quiz }

    it "reports processing while the job is pending" do
      get smart_match_result_path # enqueues the job (test adapter: not run)

      get status_smart_match_result_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("processing")
    end

    it "reports ready once matches are persisted and the page renders them" do
      allow(SmartMatch::SubmissionProcessor).to receive(:call) do |session_id:, **|
        submission = create(:quiz_submission, session_id: session_id, user_type: "donor")
        create(:organization_match, quiz_submission: submission)
        {submission: submission, results: []}
      end

      perform_enqueued_jobs { get smart_match_result_path }

      get status_smart_match_result_path
      expect(response.parsed_body["status"]).to eq("ready")

      get smart_match_result_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.results.retake"))
    end

    it "reports unavailable when the job recorded a terminal error" do
      get smart_match_result_path # establishes the session
      session_id = request.session.id.to_s
      Rails.cache.write(SmartMatch::ProcessSubmissionJob.error_key(session_id), true)

      get status_smart_match_result_path
      expect(response.parsed_body["status"]).to eq("unavailable")
    end
  end

  describe "terminal error rendering" do
    before { complete_minimum_quiz }

    it "shows the unavailable page and clears the flag so a retry starts fresh" do
      get smart_match_result_path
      session_id = request.session.id.to_s
      Rails.cache.write(SmartMatch::ProcessSubmissionJob.error_key(session_id), true)

      get smart_match_result_path
      expect(response.body).to include(I18n.t("smart_match.results.unavailable.title"))

      # Flag cleared -> the next visit re-enqueues instead of sticking on the error.
      expect(Rails.cache.exist?(SmartMatch::ProcessSubmissionJob.error_key(session_id))).to be(false)
    end
  end
end
