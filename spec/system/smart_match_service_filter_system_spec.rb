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
  let(:trigger) { I18n.t("smart_match.results.service_filter.select") }
  let(:close_label) { I18n.t("smart_match.results.service_filter.close") }

  # Matching is enqueued by the results page and normally runs on Sidekiq, which
  # is not running here -- the page would poll its spinner forever. Inline makes
  # the job run inside the request that enqueues it, so the walk reaches real
  # results, which is the only state this filter exists in.
  #
  # That also puts the job's work inside a navigation Ferrum is timing, and the
  # 5s default is not enough for it, hence the raised driver timeout. Set here
  # rather than in the shared driver so no other spec's slowness gets hidden.
  around do |example|
    was_adapter = ActiveJob::Base.queue_adapter
    was_timeout = page.driver.browser.timeout
    ActiveJob::Base.queue_adapter = :inline
    page.driver.browser.timeout = 30
    example.run
  ensure
    ActiveJob::Base.queue_adapter = was_adapter
    page.driver.browser.timeout = was_timeout
  end

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

  # The donor path, end to end, as a user walks it. Slower than seeding the
  # session, but the results page keys on a completion token the quiz mints, and
  # a filter that only works for a hand-built session is not worth verifying.
  def complete_donor_quiz
    visit smart_match_quiz_path

    pick I18n.t("smart_match.quiz.steps.user_type.options.donor")
    pick "Food security"
    pick I18n.t("smart_match.quiz.steps.donor_giving_style.options.general_donation")
    pick I18n.t("smart_match.quiz.steps.donor_giving_inspiration.options.local_community")
    pick I18n.t("smart_match.quiz.steps.donor_communities.options.no_preference")
    pick I18n.t("smart_match.quiz.steps.donor_impact_location.options.near_me")
    pick "Nashville"
    pick I18n.t("smart_match.quiz.steps.donor_involvement.options.one_time_donation")
    # Personal Details are three selects rather than cards, and the wizard keeps
    # NEXT disabled until EVERY select on the step has a value
    # (smart_match_quiz_controller#hasAnySelection), so all three are answered
    # even though the answers are irrelevant here.
    select I18n.t("smart_match.quiz.steps.final.age_range.options.prefer_not_to_say"), from: "age_range"
    select I18n.t("smart_match.quiz.steps.final.gender_identity.options.prefer_not_to_say"), from: "gender_identity"
    select I18n.t("smart_match.quiz.steps.final.race_ethnicity.options.prefer_not_to_say"), from: "race_ethnicity"
    advance
    find("button[type='submit']", text: I18n.t("smart_match.quiz.buttons.find_matches")).click

    click_on I18n.t("smart_match.confirmation.submit")
    expect(page).to have_link(I18n.t("smart_match.results.still_need_help"), wait: 20)
  end

  # Clicks an option by its visible label, then advances the wizard.
  #
  # Every step is a full navigation, so the walk has to wait for each one to
  # land before looking for the next step's options. Waiting on the step number
  # the wizard publishes is what makes that deterministic -- waiting on the
  # options' text instead raced the redirect, and failed on whichever step the
  # machine happened to be slow serving.
  def pick(label)
    find("label", text: label, wait: 20).click
    advance
  end

  # Clicks NEXT and waits for the step the wizard publishes to change.
  def advance
    departed = wizard_step

    find("button[type='submit']", text: I18n.t("smart_match.quiz.buttons.next")).click

    expect(page).to have_css(
      %(.sm-wizard:not([data-smart-match-quiz-step-value="#{departed}"])), wait: 20
    )
  end

  def wizard_step
    find(".sm-wizard", wait: 20)["data-smart-match-quiz-step-value"]
  end

  def card_names
    all("#smart-match-results article h3").map(&:text)
  end

  # Waits for the card count rather than reading it. Applying the filter and
  # returning from the quiz both swap the results frame, and a bare `all` can
  # catch that swap in flight -- the old cards are already detached and the new
  # ones are not in the document yet -- reporting a count no user ever sees.
  # The swap is a server round trip, so it can outlast the 2s default wait.
  def expect_cards(count)
    expect(page).to have_css("#smart-match-results article", count: count, wait: 10)
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
