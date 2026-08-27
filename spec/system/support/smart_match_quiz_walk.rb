# frozen_string_literal: true

# Walks the Smart Match quiz the way a user does, for system specs about what
# happens AFTER it.
#
# Extracted because every results-page system spec has to get past the quiz
# first, and the results page keys on a completion token the quiz mints -- a
# hand-built session does not reach the state these specs exist to check. The
# walk is also the fragile part (each step is a full navigation), so it is worth
# having exactly one copy of it.
module SmartMatchQuizWalk
  # Matching is enqueued by the results page and normally runs on Sidekiq, which
  # is not running here -- the page would poll its spinner forever. Inline makes
  # the job run inside the request that enqueues it, so the walk reaches real
  # results.
  #
  # That also puts the job's work inside a navigation Ferrum is timing, and the
  # 5s default is not enough for it, hence the raised driver timeout. Scoped to
  # the including spec so no other spec's slowness gets hidden.
  def self.included(base)
    base.around do |example|
      was_adapter = ActiveJob::Base.queue_adapter
      was_timeout = page.driver.browser.timeout
      ActiveJob::Base.queue_adapter = :inline
      page.driver.browser.timeout = 30
      example.run
    ensure
      ActiveJob::Base.queue_adapter = was_adapter
      page.driver.browser.timeout = was_timeout
    end
  end

  # The donor path, end to end. Slower than seeding the session, but a filter --
  # or a focus target -- that only works for a hand-built session is not worth
  # verifying.
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

  # Waits for the card count rather than reading it. Anything that swaps the
  # results frame can be caught in flight by a bare `all` -- the old cards
  # already detached, the new ones not yet in the document -- reporting a count
  # no user ever sees. The swap is a server round trip, so it can outlast the
  # 2s default wait.
  def expect_cards(count)
    expect(page).to have_css("#smart-match-results article", count: count, wait: 10)
  end
end
