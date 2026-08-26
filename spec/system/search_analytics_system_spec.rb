require "system_helper"

RSpec.describe "Search analytics tracking", type: :system do
  before do
    # Same pattern as location_search_system_spec.rb: without this, third-party
    # scripts (Maps, Bing, Clarity, the accessibility widget) can hang or mutate
    # the page mid-test, which shows up as Ferrum::NodeNotFoundError/
    # PendingConnectionsError on whatever element Capybara happens to be
    # interacting with at the time.
    #
    # Scoped to Script rather than intercepting everything: an unscoped intercept
    # proxies every request on the page over CDP into Ruby, which is slow and is
    # itself a source of timing flake. All four of these are script loads.
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

  it "pushes a search event to the GTM dataLayer when a search is submitted" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)

    # This text only renders once show.html.slim (the results template) has
    # rendered, which only happens after the search actually went through.
    expect(page).to have_text(/results? found/i, wait: 5)

    search_event = wait_for_data_layer_event("search")

    expect(search_event).not_to be_nil, "dataLayer at failure: #{fetch_data_layer.inspect}"
    # Check the full payload, not just that the event fired — a bad selector
    # elsewhere (e.g. location) wouldn't be caught by presence alone.
    expect(search_event["search_term"]).to eq("food pantry")
    expect(search_event["search_category"]).to eq("Find Help")
    # A paramless visit to /search renders _preview.html.slim, so this is a
    # first search from the search page rather than a refinement.
    expect(search_event["search_origin"]).to eq("search_landing")
    expect(search_event["search_location"]).to be_present
  end

  it "distinguishes a refinement made from the results template" do
    # Params present, so SearchesController#show renders show.html.slim — the
    # template users refine an existing search from.
    visit search_path(search: {keyword: "seed"})
    expect(page).to have_text(/results? found/i, wait: 5)

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)
    expect(page).to have_text(/results? found/i, wait: 5)

    search_event = wait_for_data_layer_event("search")

    expect(search_event).not_to be_nil, "dataLayer at failure: #{fetch_data_layer.inspect}"
    expect(search_event["search_term"]).to eq("food pantry")
    expect(search_event["search_origin"]).to eq("search_results")
  end

  # The bug this guard exists for. The tracking controller rides on the same form
  # as the `search` controller, whose submitForm() is requestSubmit() — a real
  # submit event. Every pill, distance button and city change therefore re-fires
  # the tracking action with the keyword unchanged. Counting those would turn one
  # search into five and corrupt the top-terms report.
  it "does not re-fire the search event when a filter is toggled" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)
    expect(page).to have_text(/results? found/i, wait: 5)
    wait_for_data_layer_event("search")

    expect(search_event_count).to eq(1)

    click_link "Hours"
    find("label", text: "Open Now").click

    # Sync on the filter having actually been applied before counting again —
    # the results text is already on screen, so it proves nothing here.
    expect(page).to have_current_path(/open_now/, url: true, wait: 5)

    expect(search_event_count).to eq(1)
  end

  describe "from a nonprofit detail page" do
    it "tracks the search" do
      location = create(:location, :with_office_hours)

      visit location_path(location)

      find("#search-keyword-input").set("food pantry")
      find("#search-keyword-input").send_keys(:enter)

      expect(page).to have_text(/results? found/i, wait: 5)

      search_event = wait_for_data_layer_event("search")

      expect(search_event).not_to be_nil, "dataLayer at failure: #{fetch_data_layer.inspect}"
      expect(search_event["search_term"]).to eq("food pantry")
      expect(search_event["search_category"]).to eq("Find Help")
      expect(search_event["search_origin"]).to eq("nonprofit_profile")
    end
  end

  describe "from the homepage hero form" do
    it "tracks the search, with the location that was actually submitted" do
      visit root_path

      find(:test_id, "home_search_input").fill_in with: "food pantry"
      click_button "home_search_btn"

      expect(page).to have_text(/results? found/i, wait: 5)

      search_event = wait_for_data_layer_event("search")

      expect(search_event).not_to be_nil, "dataLayer at failure: #{fetch_data_layer.inspect}"
      expect(search_event["search_term"]).to eq("food pantry")
      expect(search_event["search_category"]).to eq("Find Help")
      expect(search_event["search_origin"]).to eq("home")
      # Asserted, not just present: the location was silently `undefined` for a
      # while because the selector picked up the navbar's <p> instead of the
      # search bar's <input>, and presence-only assertions never caught it.
      expect(search_event["search_location"]).to be_present
    end

    it "neither searches nor navigates when only the location changes" do
      visit root_path

      navbar_location = "#main-navbar [data-geolocation-target='currentLocation']"
      current_city = find(navbar_location, match: :first).text

      within("form[data-controller~='search-tracking']") do
        find("input[data-geolocation-target='currentLocation']").click
        other_city = all("[data-geolocation-target='presets'] li")
          .map(&:text)
          .find { |text| text.present? && text != current_city && text != "Search near me" }
        find("[data-geolocation-target='presets'] li", text: other_city, match: :first).click
        @picked_city = other_city
      end

      # Sync on the location change having fully propagated before asserting
      # that nothing *else* happened as a result of it.
      expect(page).to have_css(navbar_location, text: @picked_city, wait: 5)

      expect(page).to have_current_path(root_path)
      expect(search_event_count).to eq(0)
    end
  end

  private

  # Turbo may still be swapping frames the instant navigation "completes" per
  # have_current_path, so a single evaluate_script read can race and see an
  # empty/stale dataLayer. Poll instead of reading it exactly once.
  #
  # A monotonic deadline rather than Timeout.timeout: Timeout raises
  # asynchronously, which can land mid-CDP-round-trip and desync the Ferrum
  # websocket, leaving the failure path to make another call on a connection
  # that is no longer healthy.
  def wait_for_data_layer_event(event_name, timeout: 10)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    loop do
      event = fetch_data_layer.reverse.find { |entry| entry["event"] == event_name }
      return event if event
      return nil if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 0.1
    end
  end

  def search_event_count
    fetch_data_layer.count { |entry| entry["event"] == "search" }
  end

  # IMPORTANT: don't JSON.stringify the whole dataLayer array. GTM pushes its
  # own internal entries (gtm.historyChange-v2, etc.) that can contain
  # unserializable/circular structures, which makes JSON.stringify throw
  # "Converting circular structure to JSON" for the *entire* array — not just
  # the offending entry. Pluck only the specific scalar fields we assert on:
  # those are always plain strings, so this can't hit a circular reference.
  def fetch_data_layer
    Array(page.evaluate_script(<<~JS))
      (function() {
        var dataLayer = window.dataLayer || [];
        var out = [];
        for (var i = 0; i < dataLayer.length; i++) {
          var entry = dataLayer[i];
          if (entry && typeof entry === "object" && "event" in entry) {
            out.push({
              event: entry.event,
              search_term: entry.search_term,
              search_category: entry.search_category,
              search_origin: entry.search_origin,
              search_location: entry.search_location
            });
          }
        }
        return out;
      })();
    JS
  end
end
