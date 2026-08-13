# frozen_string_literal: true

require "system_helper"

# The "more below" cue on quiz steps.
#
# Steps with many options run past the fold and the sticky footer reads as the
# end of the page, so users were missing options underneath. The cue has to be
# honest in both directions: present while there is more to scroll, gone once the
# last option is in view -- a permanently-visible fade would just move the lie.
RSpec.describe "Smart Match scroll cue", type: :system do
  # Short enough that any step overflows, which is the situation under test.
  before { page.driver.resize(900, 500) }

  def more_below
    page.find(".sm-wizard")["data-more-below"]
  end

  it "flags more content on a step that overflows the viewport" do
    visit smart_match_quiz_path

    expect(page).to have_css(".sm-wizard[data-more-below='true']")
  end

  it "clears the flag once the bottom of the step is reached" do
    visit smart_match_quiz_path
    expect(more_below).to eq("true")

    scroll_to_bottom

    expect(page).to have_css(".sm-wizard[data-more-below='false']")
  end

  it "re-evaluates when a taller step is loaded" do
    visit smart_match_quiz_path
    scroll_to_bottom
    expect(more_below).to eq("false")

    # Causes: the longest step in the quiz, and the one that prompted this.
    choose_volunteer_and_continue

    expect(page).to have_css(".sm-wizard[data-more-below='true']")
  end

  # Whichever element scrolls, the cue tracks it -- the wizard's content pane is
  # a flex child with overflow-y-auto, so it may or may not be the scroller
  # depending on how the flex line resolves.
  it "tracks the element that actually scrolls" do
    visit smart_match_quiz_path

    pane_scrolls = page.evaluate_script(<<~JS)
      (() => {
        const pane = document.querySelector("[data-scroll-cue-target='pane']")
        return pane.scrollHeight - pane.clientHeight > 1
      })()
    JS

    scroll_to_bottom
    expect(more_below).to eq("false")

    # Reported so a future layout change shows up in the output rather than as a
    # silently-untested branch.
    puts "  (pane is the scroller: #{pane_scrolls})"
  end

  def scroll_to_bottom
    page.execute_script(<<~JS)
      const pane = document.querySelector("[data-scroll-cue-target='pane']")
      const scroller = pane.scrollHeight - pane.clientHeight > 1 ? pane : document.scrollingElement
      scroller.scrollTop = scroller.scrollHeight
    JS
    sleep 0.2 # one animation frame plus slack for the rAF-throttled update
  end

  # Capybara's own click_button is shadowed by CupriteHelpers (it looks up a
  # test id), so drive the footer button by its text.
  def choose_volunteer_and_continue
    find("label", text: I18n.t("smart_match.quiz.steps.user_type.options.volunteer")).click
    find("button[type='submit']", text: "NEXT").click
    expect(page).to have_css("[data-card-group]")
  end
end
