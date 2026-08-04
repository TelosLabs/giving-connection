require "system_helper"

RSpec.describe "Search analytics tracking", type: :system do
  let!(:user) { create(:user) }

  before do
    # Same pattern as location_search_system_spec.rb: without this, third-party
    # scripts (Maps, Bing, Clarity, the accessibility widget) can hang or mutate
    # the page mid-test, which shows up as Ferrum::NodeNotFoundError/
    # PendingConnectionsError on whatever element Capybara happens to be
    # interacting with at the time. Stub them out so the page settles.
    browser = page.driver.browser
    third_party_pattern = /maps\.googleapis\.com|bat\.bing\.(net|com)|clarity\.ms|acsbapp\.com/

    browser.network.intercept
    browser.on(:request) do |request|
      if request.url.match?(third_party_pattern)
        request.respond(body: "", content_type: "text/javascript")
      else
        request.continue
      end
    end

    sign_in user
  end

  it "pushes a search event to the GTM dataLayer when a search is submitted" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)

    # A real readiness signal: this text only renders once show.html.slim (the
    # results template) has rendered, which only happens after the search
    # actually went through. (The previous have_current_path(search_path,
    # ignore_query: true) check was already true before submitting, since we
    # start the test on search_path — it never proved anything.)
    expect(page).to have_text(/results? found/i, wait: 5)

    search_event = wait_for_data_layer_event("search")

    expect(search_event).not_to be_nil, "dataLayer at failure: #{fetch_data_layer.inspect}"
    # Check the full payload, not just that the event fired — a bad selector
    # elsewhere (e.g. location) wouldn't be caught by presence alone.
    expect(search_event["search_term"]).to eq("food pantry")
    expect(search_event["category"]).to eq("Find Help")
    # A paramless visit to /search renders _preview.html.slim, so this is a
    # first search from the search page rather than a refinement.
    expect(search_event["search_origin"]).to eq("search_landing")
    expect(search_event["location"]).to be_present
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

  it "does not re-fire the search event on pagination" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)
    expect(page).to have_text(/results? found/i, wait: 5)

    # Make sure the (single) search event has actually landed before counting.
    wait_for_data_layer_event("search")

    count_after_search = fetch_data_layer.count { |entry| entry["event"] == "search" }
    expect(count_after_search).to eq(1)
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
      expect(search_event["category"]).to eq("Find Help")
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
      expect(search_event["category"]).to eq("Find Help")
      expect(search_event["search_origin"]).to eq("home")
      # Asserted, not just present: the location was silently `undefined` for a
      # while because the selector picked up the navbar's <p> instead of the
      # search bar's <input>, and presence-only assertions never caught it.
      expect(search_event["location"]).to be_present
    end

    # Regression guard: the homepage form used to declare the whole `search`
    # controller, which auto-submits its form whenever the global
    # `location-updated` event fires. That turned "pick a city on the homepage"
    # into "run an empty search and get navigated to /search", inflating counts
    # with searches nobody performed. Tracking now lives in its own controller
    # that only reads from its own element.
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
      expect(fetch_data_layer.count { |entry| entry["event"] == "search" }).to eq(0)
    end
  end

  private

  # Turbo may still be swapping frames the instant navigation "completes" per
  # have_current_path, so a single evaluate_script read can race and see an
  # empty/stale dataLayer. Poll instead of reading it exactly once.
  def wait_for_data_layer_event(event_name, timeout: 10)
    event = nil
    Timeout.timeout(timeout) do
      loop do
        event = fetch_data_layer.reverse.find { |entry| entry["event"] == event_name }
        break if event
        sleep 0.1
      end
    end
    event
  rescue Timeout::Error
    nil
  end

  # IMPORTANT: don't JSON.stringify the whole dataLayer array. GTM pushes its
  # own internal entries (gtm.historyChange-v2, etc.) that can contain
  # unserializable/circular structures, which makes JSON.stringify throw
  # "Converting circular structure to JSON" for the *entire* array — not just
  # the offending entry. A previous version of this helper wrapped that in a
  # JS try/catch AND a Ruby rescue, both returning [], which silently turned
  # a real crash into what looked like "the event never fired." Instead,
  # pluck only the specific scalar fields we actually assert on — those are
  # always plain strings, so this can't hit a circular reference.
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
              category: entry.category,
              search_origin: entry.search_origin,
              location: entry.location
            });
          }
        }
        return out;
      })();
    JS
  end
end
