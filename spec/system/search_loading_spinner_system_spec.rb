require "system_helper"

# Regression coverage for search_loading_controller.js: the <form> driving
# each of these turbo-frames (blog-search, search-locations) lives OUTSIDE
# the frame it targets (via data-turbo-frame), so turbo:before-fetch-request
# dispatches with the form as event.target -- which never bubbles into a
# sibling frame. The controller used to listen on the frame element itself
# and so never saw it. Verified here by observing the spinner's class
# mutations directly (via a MutationObserver installed before triggering the
# navigation), rather than racing a fast local response.
RSpec.describe "Search loading spinner", type: :system do
  before do
    browser = page.driver.browser
    third_party_pattern = /maps\.googleapis\.com|bat\.bing\.(net|com)|clarity\.ms|acsbapp\.com/

    browser.network.intercept(resource_type: "Script")
    browser.on(:request) do |request|
      if request.url.match?(third_party_pattern)
        request.respond(body: "", content_type: "text/javascript")
      else
        request.continue
      end
    end
  end

  def observe_spinner(selector)
    page.execute_script(<<~JS)
      window.__spinnerSeenVisible = false;
      const spinner = document.querySelector('#{selector}');
      const observer = new MutationObserver(() => {
        if (!spinner.classList.contains('hidden')) {
          window.__spinnerSeenVisible = true;
        }
      });
      observer.observe(spinner, { attributes: true, attributeFilter: ['class'] });
    JS
  end

  def spinner_was_seen_visible?
    page.evaluate_script("window.__spinnerSeenVisible")
  end

  describe "blogs#index" do
    it "shows the spinner and updates the list when clicking a filter tab" do
      create(:blog, title: "Nonprofit Story", blog_tag: "Nonprofits", published: true)
      create(:blog, title: "Community Story", blog_tag: "Community", published: true)

      visit blogs_path
      expect(page).to have_content("Nonprofit Story")
      expect(page).to have_content("Community Story")

      observe_spinner('[data-search-loading-target="spinner"]')
      click_link "Nonprofits (1)"

      expect(page).to have_content("Nonprofit Story")
      expect(page).not_to have_content("Community Story")
      expect(spinner_was_seen_visible?).to be(true),
        "spinner never lost its 'hidden' class during the tab-click navigation"
    end

    it "shows the spinner and updates the list/count when submitting a keyword search" do
      create(:blog, title: "Zyxqrt Findable Story", published: true)
      create(:blog, title: "Unrelated Story", published: true)

      visit blogs_path
      expect(page).to have_content("All posts (2)")

      observe_spinner('[data-search-loading-target="spinner"]')
      fill_in "Search blogs...", with: "Zyxqrt"

      expect(page).to have_content("All posts (1)", wait: 5)
      expect(page).to have_content("Zyxqrt Findable Story")
      expect(page).not_to have_content("Unrelated Story")
      expect(spinner_was_seen_visible?).to be(true),
        "spinner never lost its 'hidden' class during the debounced keyword search"
    end
  end

  describe "searches#show" do
    # A cold GET /search with no search params renders a different template
    # (_preview.html.erb) that doesn't even have the "search-locations" frame
    # -- SearchesController#show only renders the results template (where the
    # spinner lives) once a search has actually been submitted. Landing
    # directly on it with a keyword param, like following a link/bookmark
    # with a query already attached, skips the preview step.
    before { visit search_path(search: {keyword: "food", city: "Search all"}) }

    it "shows the spinner when submitting a new keyword search from the results page" do
      expect(page).to have_css('#search-locations [data-search-loading-target="spinner"]', visible: :all)

      observe_spinner('#search-locations [data-search-loading-target="spinner"]')
      find("#search-keyword-input").set("pantry")
      page.execute_script('document.querySelector("#search-keyword-input").closest("form").requestSubmit()')

      expect(page).to have_text(/results? found/i, wait: 5)
      expect(spinner_was_seen_visible?).to be(true),
        "spinner never lost its 'hidden' class during the keyword search submission"
    end

    it "shows the spinner when changing the location" do
      observe_spinner('#search-locations [data-search-loading-target="spinner"]')

      # Drives the exact event the preset-city/geolocation UI dispatches
      # (geolocation_controller.js#updateCityAndForm) rather than fighting
      # the dropdown's responsive mobile/desktop duplicate markup -- this is
      # the real code path, just triggered directly instead of via a click
      # sequence through UI that isn't what this fix touches.
      page.execute_script(<<~JS)
        window.dispatchEvent(new CustomEvent('location-updated', { detail: { latitude: 36.16, longitude: -86.78 } }));
      JS

      expect(page).to have_text(/results? found/i, wait: 5)
      expect(spinner_was_seen_visible?).to be(true),
        "spinner never lost its 'hidden' class during the location change"
    end
  end
end
