# frozen_string_literal: true

require "system_helper"

RSpec.describe "Feedback widget", type: :system do
  before do
    create(:cause)
    allow(Rack::Attack).to receive(:enabled).and_return(false)
    visit discover_path
    # The widget is position: fixed, and Ferrum resolves click coordinates
    # against the document. Give the page a viewport tall enough that it never
    # scrolls, so the two coordinate spaces agree.
    page.driver.resize_window(1200, 1400)
  end

  def open_widget
    find("button[aria-label='Give feedback']").click
  end

  it "opens, takes a rating and a category, and submits" do
    open_widget

    expect(page).to have_text("Please tell us about your experience")
    submit = find("button[type='submit']")
    expect(submit).to be_disabled

    find("button[aria-label='Love it']").click
    expect(submit).not_to be_disabled

    find("button[aria-haspopup='listbox']").click
    find("button[role='option']", text: "Ease of use").click

    # The trigger label shows the option's own icon + text, cloned from the
    # server-rendered option rather than rebuilt in JS.
    within "[data-feedback-target='dropdownLabel']" do
      expect(page).to have_text("Ease of use")
      expect(page).to have_css("svg")
    end

    fill_in "feedback[comment]", with: "The discover page is clear."

    expect { submit.click }.to change(Feedback, :count).by(1)

    expect(page).to have_text(FeedbacksController::SUCCESS_MESSAGE)

    feedback = Feedback.last
    expect(feedback.rating).to eq(5)
    expect(feedback.category).to eq("ease_of_use")
    expect(feedback.context).to eq("discover")
  end

  describe "category listbox keyboard support" do
    before { open_widget }

    it "tracks the open state on the trigger" do
      trigger = find("button[aria-haspopup='listbox']")
      expect(trigger["aria-expanded"]).to eq("false")

      trigger.click
      expect(trigger["aria-expanded"]).to eq("true")

      trigger.click
      expect(trigger["aria-expanded"]).to eq("false")
    end

    it "walks the options with the arrow keys and closes on Escape" do
      trigger = find("button[aria-haspopup='listbox']")
      trigger.click

      labels = Feedback::CATEGORY_OPTIONS.values.map(&:first)

      press(:Down)
      expect(focused_option_text).to eq(labels.first)

      press(:Down)
      expect(focused_option_text).to eq(labels.second)

      press(:Up)
      expect(focused_option_text).to eq(labels.first)

      press(:Escape)
      expect(trigger["aria-expanded"]).to eq("false")
      expect(page).to have_css("[data-feedback-target='dropdownMenu'].hidden", visible: :all)
    end

    it "selects the focused option with Enter" do
      trigger = find("button[aria-haspopup='listbox']")
      trigger.click
      press(:Down)
      press(:Enter)

      expect(find("[data-feedback-target='categoryInput']", visible: :all).value)
        .to eq(Feedback::CATEGORY_OPTIONS.keys.first)
    end
  end

  # Turbo snapshots the page before navigating away and repaints that snapshot
  # on Back. Without a before-cache reset the visitor would come back to a panel
  # (or an exit-intent modal, backdrop and all) that is already open.
  it "collapses the panel before Turbo caches the page" do
    open_widget
    expect(page).to have_text("Please tell us about your experience")

    page.execute_script("document.dispatchEvent(new CustomEvent('turbo:before-cache'))")

    expect(page).to have_css("[data-feedback-target='panel'].hidden", visible: :all)
    expect(page).to have_css("button[aria-label='Give feedback']")
  end

  # A throttled or failing POST returns no success stream, so without this the
  # panel would just sit there with the form filled in and no explanation.
  it "shows an error and re-enables submit when the POST fails" do
    allow_any_instance_of(Feedback).to receive(:save).and_return(false)

    open_widget
    find("button[aria-label='Mad']").click
    submit = find("button[type='submit']")
    submit.click

    expect(page).to have_text("Something went wrong, please try again.")
    expect(page).to have_text("Please tell us about your experience")
    expect(submit).not_to be_disabled
  end

  def press(key)
    page.driver.browser.keyboard.type(key)
  end

  def focused_option_text
    page.evaluate_script("document.activeElement.textContent.trim()")
  end
end
