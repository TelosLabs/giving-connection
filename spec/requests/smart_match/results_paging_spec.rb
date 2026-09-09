# frozen_string_literal: true

require "rails_helper"

# What the results page actually puts on screen.
#
# The page used to render a fixed three cards regardless of how many matches the
# pipeline found. It now shows the whole top match tier -- reaching into the next
# tier when the top one is thin -- and pages the rest in behind "Show more".
RSpec.describe "SmartMatch::Results paging", type: :request do
  include ActiveJob::TestHelper

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  # Raw scores: 0.75 displays as 91% (great tier), 0.45 as 68% (good tier).
  # See spec/models/organization_match_spec.rb for the calibration.
  let(:great) { 0.75 }
  let(:good) { 0.45 }

  before do
    # Test env uses :null_store; the controller and job coordinate through the
    # cache, so swap in a real store shared by both.
    allow(Rails).to receive(:cache).and_return(memory_cache)
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  # Puts a submission with `scores` worth of matches behind the current session,
  # the same way the background job would.
  def complete_quiz_with(scores, breakdown: {})
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: %w[Education]}

    allow(SmartMatch::SubmissionProcessor).to receive(:call) do |session_id:, attempt_token:, **|
      submission = create(:quiz_submission, session_id: session_id,
        attempt_token: attempt_token, user_type: "donor")
      SmartMatchMatchRows.insert(submission: submission, scores: scores, breakdown: breakdown)
      {submission: submission, results: []}
    end

    perform_enqueued_jobs { get smart_match_result_path }
  end

  def card_count
    Nokogiri::HTML(response.body).css("#smart-match-results article").size
  end

  it "shows the whole top tier rather than a fixed three" do
    complete_quiz_with([great] * 8 + [good] * 12)

    get smart_match_result_path

    expect(card_count).to eq(8)
    expect(response.body).to include(I18n.t("smart_match.results.show_more", count: 12))
  end

  it "reaches into the next tier when the top one is too thin to fill a page" do
    complete_quiz_with([great] * 2 + [good] * 9)

    get smart_match_result_path

    expect(card_count).to eq(11)
  end

  it "caps the first page and offers the rest" do
    complete_quiz_with([great] * 25)

    get smart_match_result_path

    expect(card_count).to eq(20)
    expect(response.body).to include(I18n.t("smart_match.results.show_more", count: 5))
    expect(response.body).to include(smart_match_result_path(page: 2))
  end

  it "adds the next batch on the following page" do
    complete_quiz_with([great] * 25)

    get smart_match_result_path(page: 2)

    expect(card_count).to eq(25)
    expect(response.body).not_to include(I18n.t("smart_match.results.show_more", count: 5))
  end

  it "does not offer more when everything is already shown" do
    complete_quiz_with([great] * 4)

    get smart_match_result_path

    expect(card_count).to eq(4)
    expect(response.body).not_to include("Show more")
    expect(response.body).not_to include(smart_match_result_path(page: 2))
  end

  # Replacing the frame destroys the button that was just activated, so focus
  # falls back to <body> -- a keyboard user is dropped at the top of the
  # document and a screen reader is told nothing, because the count line's
  # aria-live region is itself replaced rather than updated in place.
  # smart-match-results-focus moves focus onto the count line instead; these are
  # the four attributes it needs to do that.
  it "wires the frame so focus can follow a Show more into the new results" do
    complete_quiz_with([great] * 25)

    get smart_match_result_path
    frame = Nokogiri::HTML(response.body).at_css("turbo-frame#smart-match-results")

    expect(frame["data-controller"]).to include("smart-match-results-focus")
    expect(frame["data-action"]).to include("turbo:frame-load->smart-match-results-focus#focusStatus")

    status = frame.at_css("[data-smart-match-results-focus-target='status']")
    expect(status["tabindex"]).to eq("-1")
    expect(status["role"]).to eq("status")

    expect(frame.at_css("a[data-action*='smart-match-results-focus#arm']")).to be_present
  end

  # "?page=" is throttled at the browsing ceiling (60/hr) rather than the
  # results ceiling (10/hr), on the grounds that a paged request is a pure read
  # of matches that already exist. That only holds if a paged request can never
  # start the pipeline -- otherwise a session whose submission is missing (a
  # failing embedding service, an expired error flag) could re-enqueue the
  # expensive path at six times the intended rate.
  it "sends a paged request with nothing to page to the unpaged URL" do
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: %w[Education]}

    expect {
      get smart_match_result_path(page: 3)
    }.not_to change { enqueued_jobs.size }

    expect(response).to redirect_to(smart_match_result_path)
  end

  # The cards and the "how we matched you" panel are swapped together, because
  # the panel counts how many of the SHOWN matches meet each criterion.
  it "keeps the cards and the criteria panel in the same Turbo frame" do
    complete_quiz_with([great] * 25,
      breakdown: {"criteria" => [{"question" => "causes", "answer" => "Education", "status" => "met"}]})

    get smart_match_result_path

    frame = Nokogiri::HTML(response.body).at_css("turbo-frame#smart-match-results")
    expect(frame).to be_present
    expect(frame.css("details").size).to eq(1)
    expect(frame.css("article").size).to eq(20)
  end
end
