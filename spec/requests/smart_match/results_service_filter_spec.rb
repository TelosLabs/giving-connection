# frozen_string_literal: true

require "rails_helper"

# The "looking for a specific service?" control on the results page.
#
# Services were a quiz question until they tested badly -- most people don't
# know the vocabulary and being asked up front made them stop and wonder
# whether they should. Here it is a post-hoc filter: invisible until opened,
# free to ignore, and incapable of changing the ranking.
RSpec.describe "SmartMatch::Results service filter", type: :request do
  include ActiveJob::TestHelper

  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    # Test env uses :null_store; the controller and job coordinate through the
    # cache, so swap in a real store shared by both.
    allow(Rails).to receive(:cache).and_return(memory_cache)
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  # specs: [{name:, services: [...]}, ...] in rank order, best first.
  def complete_quiz_matching(specs)
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: %w[Education]}

    allow(SmartMatch::SubmissionProcessor).to receive(:call) do |session_id:, attempt_token:, **|
      submission = create(:quiz_submission, session_id: session_id,
        attempt_token: attempt_token, user_type: "donor")
      specs.each_with_index { |spec, index| match_for(submission, spec, index) }
      {submission: submission, results: []}
    end

    perform_enqueued_jobs { get smart_match_result_path }
  end

  def match_for(submission, spec, index)
    organization = create(:organization, name: spec[:name], ein_number: "12-000000#{index}")
    organization.locations.first.services = Array(spec[:services]).map do |name|
      Service.find_or_create_by!(name: name) { |s| s.cause = Cause.find_or_create_by!(name: "Education") }
    end

    create(:organization_match, quiz_submission: submission, organization: organization,
      score: 0.75 - (index / 100.0), rank: index + 1)
  end

  def card_names
    Nokogiri::HTML(response.body).css("#smart-match-results article h3").map { |h| h.text.strip }
  end

  # The one-line trigger that sits under the "how we matched you" panel.
  def filter_trigger
    Nokogiri::HTML(response.body)
      .at_css("turbo-frame#smart-match-results [data-controller='smart-match-service-dialog']")
  end

  def filter_dialog
    filter_trigger&.at_css("dialog")
  end

  let(:three_orgs) do
    [
      {name: "Shelter Org", services: ["Homeless Shelters"]},
      {name: "Support Org", services: ["Housing Support Services"]},
      {name: "Both Org", services: ["Homeless Shelters", "Housing Support Services"]}
    ]
  end

  # One line of small print, not a panel: the point of moving this out of the
  # quiz was to stop giving the question a surface of its own.
  it "invites the refinement in one line and keeps the dialog shut" do
    complete_quiz_matching(three_orgs)

    get smart_match_result_path

    trigger = filter_trigger
    expect(trigger).to be_present
    expect(trigger.text).to include(I18n.t("smart_match.results.service_filter.prompt"))
    expect(trigger.text).to include(I18n.t("smart_match.results.service_filter.select"))

    # Present in the markup but inert -- a closed <dialog> is display:none.
    expect(filter_dialog.attributes).not_to have_key("open")
    expect(filter_dialog.css("input[name='services[]']").map { |i| i["value"] })
      .to contain_exactly("Homeless Shelters", "Housing Support Services")
    expect(filter_dialog.css("input[checked]")).to be_empty
    expect(card_names.size).to eq(3)
  end

  # A modal must never open by itself on page load, so the trigger line carries
  # the "what is applied, and how do I undo it" job instead.
  it "names the active filter inline with a way out" do
    complete_quiz_matching(three_orgs)

    get smart_match_result_path(services: ["Homeless Shelters"])

    trigger = filter_trigger
    expect(trigger.text).to include(I18n.t("smart_match.results.service_filter.selected", count: 1))
    expect(trigger.at_css("a[href='#{smart_match_result_path}']")).to be_present
    expect(filter_dialog.attributes).not_to have_key("open")
  end

  it "narrows the cards to organizations offering a selected service" do
    complete_quiz_matching(three_orgs)

    get smart_match_result_path(services: ["Homeless Shelters"])

    expect(card_names).to contain_exactly("Shelter Org", "Both Org")
  end

  # Reopening the dialog has to show what is actually applied, so dismissing it
  # (which rewinds the boxes to this state) cannot drift from the results.
  it "ticks the active selection inside the dialog" do
    complete_quiz_matching(three_orgs)

    get smart_match_result_path(services: ["Homeless Shelters"])

    boxes = filter_dialog.css("input[name='services[]']")
    checked = boxes.select { |box| box.attributes.key?("checked") }.map { |box| box["value"] }

    expect(checked).to eq(["Homeless Shelters"])
  end

  it "keeps the filter on the next page of results" do
    complete_quiz_matching(
      Array.new(25) { |i| {name: "Org #{i}", services: ["Homeless Shelters"]} }
    )

    get smart_match_result_path(services: ["Homeless Shelters"])

    show_more = Nokogiri::HTML(response.body).at_css("#smart-match-results a[href*='page=2']")
    expect(show_more["href"]).to eq(smart_match_result_path(page: 2, services: ["Homeless Shelters"]))
  end

  # The whole point of moving this out of the quiz: it is a display filter, so
  # the scores and the order the pipeline produced must survive it untouched.
  it "does not change any match's score or rank" do
    complete_quiz_matching(three_orgs)
    before = OrganizationMatch.order(:rank).pluck(:organization_id, :score, :rank)

    get smart_match_result_path(services: ["Homeless Shelters"])

    expect(OrganizationMatch.order(:rank).pluck(:organization_id, :score, :rank)).to eq(before)
  end

  it "hides the control when the matches offer nothing to choose between" do
    complete_quiz_matching([{name: "Only Org", services: ["Homeless Shelters"]}])

    get smart_match_result_path

    expect(filter_trigger).to be_nil
  end

  # A stale link must degrade to showing more, not to a dead end.
  it "ignores a requested service none of the matches offer" do
    complete_quiz_matching(three_orgs)

    get smart_match_result_path(services: ["Underwater Basket Weaving"])

    expect(card_names.size).to eq(3)
    expect(filter_trigger.text).to include(I18n.t("smart_match.results.service_filter.select"))
  end
end
