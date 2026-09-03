# frozen_string_literal: true

require "system_helper"

# Where keyboard focus lands after "Show more".
#
# The button targets the smart-match-results frame, so Turbo replaces the
# frame's contents -- including the button that was just pressed. Focus has
# nowhere to return to and falls back to <body>, which drops a keyboard user at
# the top of the document and leaves a screen reader with no idea the page grew:
# the count line carries aria-live, but that element is replaced along with
# everything else, and a live region inserted together with its own content is
# not reliably announced.
#
# Only a browser can answer this -- the markup is identical either way -- so it
# gets one example, sharing the quiz walk with the other results system spec.
RSpec.describe "Smart Match show more focus", type: :system do
  include SmartMatchQuizWalk

  # 25 matches: the first page is capped at 20, so one "Show more" remains.
  # Rows are inserted rather than built through the factories -- this spec reads
  # nothing off an organization but the fact that a card exists for it.
  before do
    allow(SmartMatch::SubmissionProcessor).to receive(:call) do |session_id:, attempt_token:, **|
      submission = create(:quiz_submission, session_id: session_id,
        attempt_token: attempt_token, user_type: "donor")
      SmartMatchMatchRows.insert(submission: submission, scores: [0.75] * 25)
      {submission: submission, results: []}
    end
  end

  def focused_test_id
    page.evaluate_script("document.activeElement && document.activeElement.dataset.smartMatchResultsFocusTarget")
  end

  it "moves focus onto the new count instead of dropping it on the body" do
    complete_donor_quiz
    expect_cards(20)

    click_on I18n.t("smart_match.results.show_more", count: 5)
    expect_cards(25)

    expect(focused_test_id).to eq("status")
    expect(page).to have_text(I18n.t("smart_match.results.showing", count: 25, shown: 25))
  end
end
