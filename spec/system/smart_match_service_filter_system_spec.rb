# frozen_string_literal: true

require "system_helper"

# The results page's "Select services" dialog.
#
# Request specs cover what the server renders; these cover the part only a
# browser can answer -- that the <dialog> is inert until asked for, that
# dismissing it really is a no-op on the results behind it, and that applying
# swaps the cards in place.
#
# Examples are deliberately few and each one asserts several things: every one
# has to walk the whole donor quiz first, which is the expensive part.
RSpec.describe "Smart Match service filter", type: :system do
  # complete_donor_quiz, pick/advance and expect_cards, plus the inline-job and
  # driver-timeout setup the walk needs.
  include SmartMatchQuizWalk

  let(:trigger) { I18n.t("smart_match.results.service_filter.select") }
  let(:close_label) { I18n.t("smart_match.results.service_filter.close") }

  # Created up front rather than inside the stub: organizations are the expensive
  # half of this fixture (each builds an admin, a location and a cause), and with
  # the job running inline that cost would land inside the request the browser is
  # waiting on.
  let!(:organizations) do
    {
      "Shelter Org" => ["Homeless Shelters"],
      "Support Org" => ["Housing Support Services"],
      "Both Org" => ["Homeless Shelters", "Housing Support Services"]
    }.each_with_index.map do |(name, services), index|
      organization = create(:organization, name: name, ein_number: "12-000000#{index}")
      organization.locations.first.services = services.map { |service| service_named(service) }
      organization
    end
  end

  before do
    # The pipeline itself talks to an embedding service; the filter is a pure
    # display concern, so the matches are planted directly.
    allow(SmartMatch::SubmissionProcessor).to receive(:call) do |session_id:, attempt_token:, **|
      submission = create(:quiz_submission, session_id: session_id,
        attempt_token: attempt_token, user_type: "donor")
      plant_matches(submission)
      {submission: submission, results: []}
    end
  end

  def plant_matches(submission)
    organizations.each_with_index do |organization, index|
      create(:organization_match, quiz_submission: submission, organization: organization,
        score: 0.75 - (index / 100.0), rank: index + 1)
    end
  end

  def service_named(name)
    Service.find_or_create_by!(name: name) do |service|
      service.cause = Cause.find_or_create_by!(name: "Housing & Homelessness")
    end
  end

  def card_names
    all("#smart-match-results article h3").map(&:text)
  end

  # showModal() and close() are reflected in the <dialog>'s `open` attribute, so
  # the waiting matchers can be pointed straight at it. Reading `dialog.open`
  # through evaluate_script resolved exactly once, with no retry, which raced
  # every one of those swaps.
  def expect_dialog_open
    expect(page).to have_css("#smart-match-results dialog[open]", wait: 10)
  end

  # visible: :all so this asserts the attribute is really gone, rather than
  # passing for free on a dialog the browser has merely hidden.
  def expect_dialog_closed
    expect(page).to have_no_css("#smart-match-results dialog[open]", visible: :all)
  end

  def open_dialog
    click_on trigger
    expect_dialog_open
  end

  it "stays shut until asked for, and closes again on Escape" do
    complete_donor_quiz

    expect(page).to have_text(I18n.t("smart_match.results.service_filter.prompt"))
    expect_dialog_closed

    open_dialog
    expect(page).to have_text("Homeless Shelters")

    find("#smart-match-results dialog").send_keys(:escape)

    expect_dialog_closed
  end

  it "narrows the cards in place when applied" do
    complete_donor_quiz
    expect_cards(3)

    open_dialog
    find("#smart-match-results dialog label", text: "Homeless Shelters").click
    click_on I18n.t("smart_match.results.service_filter.apply")

    expect_cards(2)
    expect(card_names).to contain_exactly("Shelter Org", "Both Org")
    expect_dialog_closed
    # The inline trigger now reports what is applied, and offers the way out.
    expect(page).to have_text(I18n.t("smart_match.results.service_filter.selected", count: 1))
    expect(page).to have_link(I18n.t("smart_match.results.service_filter.clear"))
  end

  # Dismissing is not applying. Someone who opens this out of curiosity, ticks
  # something and closes it must find their results as they left them -- and
  # must not be shown ticks on reopening that the results do not reflect.
  it "leaves the results alone when dismissed, and rewinds the ticks" do
    complete_donor_quiz

    open_dialog
    find("#smart-match-results dialog label", text: "Homeless Shelters").click
    find("button[aria-label='#{close_label}']").click

    expect_dialog_closed
    expect_cards(3)

    open_dialog

    expect(page).to have_no_css("#smart-match-results dialog input:checked", visible: :all)
  end
end
