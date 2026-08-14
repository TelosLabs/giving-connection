# frozen_string_literal: true

require "rails_helper"

# Regression: retaking the quiz used to replay the FIRST attempt's results.
#
# Everything keyed on the Rails session id, which survives a retake (the reset
# clears the smart_match_* keys, not the session). Three failures compounded:
#
#   1. ProcessSubmissionJob returned early because a submission already existed
#      for the session, so the retake produced no submission at all.
#   2. ResultsController#find_submission fell back to the newest submission for
#      the session and pinned its id, so the old matches rendered as new.
#   3. #submission_present? reported "ready" for the same reason.
#
# Observed as: a user answering "senior / needs adult day care" being shown
# housing and mental-health matches from a previous run.
RSpec.describe "SmartMatch retake isolation", type: :request do
  include ActiveJob::TestHelper

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_cache)
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs

    allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(Array.new(1024) { 0.1 })
    allow(SmartMatch::SimilarityQuery).to receive(:call)
      .and_return(SmartMatch::SimilarityQuery::Result.new(candidates: [], relaxed: []))
  end

  # Walks a donor quiz to completion with the given causes.
  def take_quiz(causes)
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: causes}
    put smart_match_quiz_path, params: {donation_style: %w[one_time]}
    put smart_match_quiz_path, params: {giving_inspiration: %w[personal_story]}
    put smart_match_quiz_path, params: {donor_communities: %w[seniors]}
    put smart_match_quiz_path, params: {impact_location: "local"}
    put smart_match_quiz_path, params: {city_selection: "Nashville"}
    put smart_match_quiz_path, params: {donor_involvement: "active"}
    put smart_match_quiz_path, params: {age_range: "over_65"}
    put smart_match_quiz_path, params: {language_input: "x"}

    get smart_match_result_path
    perform_enqueued_jobs
  end

  def retake
    delete smart_match_quiz_path
  end

  it "creates a separate submission for each attempt" do
    take_quiz(["Housing & Homelessness"])
    retake

    expect { take_quiz(["Seniors"]) }.to change(QuizSubmission, :count).by(1)
  end

  it "shows the second attempt's answers, not the first's" do
    take_quiz(["Housing & Homelessness"])
    retake
    take_quiz(["Seniors"])

    get smart_match_result_path
    shown = QuizSubmission.find(request.session[:smart_match_submission_id])

    expect(shown.answers["causes"]).to eq(["Seniors"])
  end

  it "gives each attempt its own token" do
    take_quiz(["Housing & Homelessness"])
    first_token = request.session[:smart_match_attempt_token]

    retake
    take_quiz(["Seniors"])
    second_token = request.session[:smart_match_attempt_token]

    expect(second_token).to be_present
    expect(second_token).not_to eq(first_token)
    expect(QuizSubmission.pluck(:attempt_token).uniq).to contain_exactly(first_token, second_token)
  end

  it "does not report the new attempt as ready before its job has run" do
    take_quiz(["Housing & Homelessness"])
    retake

    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: ["Seniors"]}

    get status_smart_match_result_path
    expect(response.parsed_body["status"]).to eq("processing")
  end
end
