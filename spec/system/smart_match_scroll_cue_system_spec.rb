# frozen_string_literal: true

require "system_helper"

# The "more below" cue on quiz steps.
#
# Steps with many options run past the fold and the sticky footer reads as the
# end of the page, so users were missing options underneath. The cue has to be
# honest in both directions: present while there is more to scroll, gone once the
# last option is in view -- a permanently-visible fade would just move the lie.
#
# NOTE on waiting: the controller updates on a requestAnimationFrame and the fade
# is a 200ms transition, so every assertion about state goes through a retrying
# Capybara matcher. Reading the attribute directly after a fixed sleep is flaky,
# which it duly proved to be.
RSpec.describe "Smart Match scroll cue", type: :system do
  # Short enough that any step overflows, which is the situation under test.
  before { page.driver.resize(900, 500) }

  def expect_more_below(value)
    expect(page).to have_css(".sm-wizard[data-more-below='#{value}']")
  end

  it "flags more content on a step that overflows the viewport" do
    visit smart_match_quiz_path

    expect_more_below("true")
  end

  it "clears the flag once the bottom of the step is reached" do
    visit smart_match_quiz_path
    expect_more_below("true")

    scroll_to_bottom

    expect_more_below("false")
  end

  it "re-evaluates when a taller step is loaded" do
    visit smart_match_quiz_path
    scroll_to_bottom
    expect_more_below("false")

    # Causes: the longest step in the quiz, and the one that prompted this.
    choose_volunteer_and_continue

    expect_more_below("true")
  end

  # Whichever element scrolls, the cue tracks it -- the wizard's content pane is a
  # flex child with overflow-y-auto, so it is the scroller at some viewport sizes
  # and the document is at others.
  it "tracks the element that actually scrolls" do
    visit smart_match_quiz_path
    expect_more_below("true")

    scroll_to_bottom

    expect_more_below("false")
    # Reported so a future layout change shows up in the output rather than as a
    # silently-untested branch.
    puts "  (pane is the scroller: #{pane_scrolls?})"
  end

  describe "the chevron" do
    it "is offered while there is more below and withdrawn at the end" do
      visit smart_match_quiz_path

      expect(page).to have_css(".sm-wizard[data-more-below='true'] .sm-wizard__scroll-cue")
      expect(cue_visible?).to be(true)

      scroll_to_bottom
      expect_more_below("false")
      sleep 0.3 # the 200ms opacity transition

      # Still in the DOM (it rides the sticky footer), but faded out and
      # untargetable -- it must not be clickable while invisible.
      expect(cue_visible?).to be(false)
    end

    it "scrolls the step when tapped" do
      visit smart_match_quiz_path
      # The cue starts invisible and untargetable; clicking before the controller
      # has flagged the overflow would fail on visibility, not on behaviour.
      expect_more_below("true")
      before_scroll = scroll_top

      find(".sm-wizard__scroll-cue").click
      sleep 0.6 # smooth scrolling

      expect(scroll_top).to be > before_scroll
    end
  end

  def cue_visible?
    page.evaluate_script(<<~JS)
      (() => {
        const style = getComputedStyle(document.querySelector(".sm-wizard__scroll-cue"))
        return style.opacity === "1" && style.pointerEvents !== "none"
      })()
    JS
  end

  def pane_scrolls?
    page.evaluate_script("(() => { #{scroller_js} return s !== document.scrollingElement })()")
  end

  def scroll_top
    page.evaluate_script("(() => { #{scroller_js} return Math.round(s.scrollTop) })()")
  end

  def scroll_to_bottom
    page.execute_script("#{scroller_js} s.scrollTop = s.scrollHeight")
  end

  def scroller_js
    <<~JS
      const pane = document.querySelector("[data-scroll-cue-target='pane']")
      const s = pane.scrollHeight - pane.clientHeight > 1 ? pane : document.scrollingElement
    JS
  end

  # Capybara's own click_button is shadowed by CupriteHelpers (it looks up a test
  # id), so drive the footer button by its text.
  def choose_volunteer_and_continue
    find("label", text: I18n.t("smart_match.quiz.steps.user_type.options.volunteer")).click
    find("button[type='submit']", text: "NEXT").click
    expect(page).to have_css("[data-card-group]")
  end
end
