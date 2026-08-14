# frozen_string_literal: true

require "system_helper"

# Scrolling a quiz step: the geometry, and the cue that advertises it.
#
# Steps with many options run past the fold and the sticky footer reads as the
# end of the page, so users were missing options underneath. The cue has to be
# honest in both directions: present while there is more to scroll, gone once the
# last option is in view -- a permanently-visible fade would just move the lie.
#
# The examples about geometry are regressions for two reported bugs, both caused
# by the section being a whole viewport tall UNDER an in-flow navbar:
#   * every step ended in blank scrollable space (302px on the shorter ones), so
#     the chevron delivered users into nothing;
#   * the pane and the document traded the scrolling job depending on how tall
#     the step was, so on the causes step the fade could not be scrolled away and
#     sat on top of the last answers permanently.
#
# NOTE on waiting: the controller updates on a requestAnimationFrame and the fade
# is a 200ms transition, so every assertion about state goes through a retrying
# Capybara matcher. Reading the attribute directly after a fixed sleep is flaky,
# which it duly proved to be.
RSpec.describe "Smart Match wizard scrolling", type: :system do
  # Short enough that any step overflows, which is the situation under test.
  before { resize_to(900, 500) }

  # CDP applies a resize asynchronously, so a bare driver.resize can still be
  # settling when the example starts measuring -- which reads as a layout bug
  # rather than as the race it is. Wait for the viewport to actually be the size
  # we asked for.
  def resize_to(width, height)
    page.driver.resize(width, height)

    Timeout.timeout(2) do
      sleep 0.05 until page.evaluate_script("window.innerHeight") == height
    end
  end

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

  # The pane carries bottom clearance so answers can escape the fade. That
  # clearance is scrollable distance with nothing in it, so it must not be
  # advertised as more content -- the cue would be pointing at its own padding.
  it "stays quiet when every answer already fits" do
    page.driver.resize(1280, 800)
    visit smart_match_quiz_path

    expect_more_below("false")
  end

  describe "the geometry" do
    # Was: 302px of blank scrollable space at the end of every step, which is
    # where the chevron dropped you.
    it "leaves nothing past the last answer but the fade's own clearance" do
      visit smart_match_quiz_path
      choose_volunteer_and_continue
      expand_more_causes
      scroll_to_bottom

      # A little slack for the bottom margin of the last row.
      expect(blank_tail).to be <= clearance + 40
    end

    # Was: the last row of options came to rest under the fade and stayed
    # blurred no matter how far you scrolled.
    it "lands the last answers clear of the fade" do
      visit smart_match_quiz_path
      choose_volunteer_and_continue
      expand_more_causes
      scroll_to_bottom

      expect(last_option_bottom).to be <= fade_top + 1
    end

    # Was: expanding the accordion handed scrolling from the pane to the
    # document, and the cue then measured an element that was not moving.
    #
    # Also the regression for the collapsed accordion: its ~1660px of causes used
    # to sit in the pane's scrollable height while invisible, so expanding added
    # almost nothing (183px was the measured growth) and the step scrolled
    # through a screenful of blank instead. Growth now has to be most of the
    # accordion's real height.
    it "keeps the pane as the scroller when the accordion expands" do
      visit smart_match_quiz_path
      choose_volunteer_and_continue
      before = scroll_metrics

      expand_more_causes

      after = scroll_metrics
      expect(after["paneOverflow"] - before["paneOverflow"]).to be > 1000
      # ...and none of it landed in the document, which is what used to happen.
      expect(after["docOverflow"]).to be_within(2).of(before["docOverflow"])
    end

    # The user-visible half of the same bug: with the extra causes collapsed, the
    # bottom of the step is the "More options" button, not a screen of white.
    it "does not make the collapsed causes scrollable" do
      visit smart_match_quiz_path
      choose_volunteer_and_continue
      scroll_to_bottom

      expect(blank_tail).to be <= clearance + 40
      expect(page).to have_button(I18n.t("smart_match.quiz.steps.causes.more_options"))
    end
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

  def scroll_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const pane = document.querySelector("[data-wizard-scroll-target='pane']")
        const doc = document.scrollingElement
        return {
          paneOverflow: pane.scrollHeight - pane.clientHeight,
          docOverflow: doc.scrollHeight - doc.clientHeight
        }
      })()
    JS
  end

  def clearance
    page.evaluate_script(<<~JS)
      parseFloat(getComputedStyle(document.querySelector("[data-wizard-scroll-target='pane']")).paddingBottom)
    JS
  end

  # Scrollable distance below the bottom-most rendered content in the pane.
  def blank_tail
    page.evaluate_script(<<~JS)
      (() => {
        const pane = document.querySelector("[data-wizard-scroll-target='pane']")
        const paneTop = pane.getBoundingClientRect().top
        let contentBottom = 0
        pane.querySelectorAll("*").forEach((el) => {
          const box = el.getBoundingClientRect()
          if (box.height === 0) return
          contentBottom = Math.max(contentBottom, box.bottom + pane.scrollTop - paneTop)
        })
        return Math.round(pane.scrollHeight - contentBottom)
      })()
    JS
  end

  def last_option_bottom
    page.evaluate_script(<<~JS)
      (() => {
        const options = [...document.querySelectorAll(".sm-card-option")].filter((el) => el.getBoundingClientRect().height > 0)
        return Math.round(options[options.length - 1].getBoundingClientRect().bottom)
      })()
    JS
  end

  # Top edge of the fade: it hangs off the top of the sticky footer.
  def fade_top
    page.evaluate_script(<<~JS)
      (() => {
        const footer = document.querySelector(".sm-wizard__footer")
        const fade = parseFloat(getComputedStyle(document.querySelector(".sm-wizard")).getPropertyValue("--sm-fade-height")) * 16
        return Math.round(footer.getBoundingClientRect().top - fade)
      })()
    JS
  end

  def scroll_top
    page.evaluate_script("Math.round(document.querySelector(\"[data-wizard-scroll-target='pane']\").scrollTop)")
  end

  def scroll_to_bottom
    page.execute_script(<<~JS)
      const pane = document.querySelector("[data-wizard-scroll-target='pane']")
      pane.scrollTop = pane.scrollHeight
    JS
  end

  def expand_more_causes
    find("button", text: I18n.t("smart_match.quiz.steps.causes.more_options")).click
    sleep 0.6 # the 350ms max-height transition
  end

  # Capybara's own click_button is shadowed by CupriteHelpers (it looks up a test
  # id), so drive the footer button by its text.
  def choose_volunteer_and_continue
    find("label", text: I18n.t("smart_match.quiz.steps.user_type.options.volunteer")).click
    find("button[type='submit']", text: "NEXT").click
    # Wait on the causes step's own title: step 1 also renders a [data-card-group],
    # so waiting on that returned before the step had actually changed.
    expect(page).to have_text(I18n.t("smart_match.quiz.titles.volunteer.step_2"))
  end
end
