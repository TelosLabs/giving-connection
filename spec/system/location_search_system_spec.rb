require "system_helper"

# Exercises the location typeahead on the home hero search bar. The typeahead now
# runs server-side (LocationSearchesController + LocationAutocomplete/LocationGeocoder,
# rendered by the stimulus-autocomplete controller), so we stub those services for
# deterministic, offline tests instead of stubbing the browser Google SDK.
RSpec.describe "Location search", type: :system do
  let!(:user) { create(:user) }

  # Nationwide "Search all" preset coordinates, mirrored from geolocation_controller.
  SEARCH_ALL_LAT = "37.0902".freeze
  SEARCH_ALL_LON = "-95.7129".freeze

  let(:location_input) { find("input[data-geolocation-target='currentLocation']") }
  let(:clear_button) { find("[data-geolocation-target='clearButton']", visible: :all) }
  let(:suggestion) { "[data-autocomplete-target='results'] li[role='option']" }

  before do
    # The Google Maps <script> is still loaded (for map embeds / reverse-geocode
    # elsewhere) but unused by the typeahead. Neutralize it so the page load
    # doesn't hang waiting on the network.
    browser = page.driver.browser
    browser.network.intercept(pattern: "*maps.googleapis.com*")
    browser.on(:request) do |request|
      if request.url.include?("maps.googleapis.com")
        request.respond(
          body: "window.google = window.google || { maps: {} }; if (typeof window.initMap === 'function') window.initMap();",
          content_type: "text/javascript"
        )
      else
        request.continue
      end
    end

    # Stub the server-side location services (RSpec class stubs are visible to the
    # in-process Capybara server thread).
    allow(LocationAutocomplete).to receive(:call).and_return([
      { description: "Nashville, TN", place_id: "p1" }
    ])
    allow(LocationGeocoder).to receive(:call).and_return(
      latitude: 36.16404968727089, longitude: -86.78125827725053, city: "Nashville, TN"
    )

    sign_in user
    visit root_path
  end

  it "renders server-rendered city suggestions as the user types" do
    location_input.send_keys("Nash")

    expect(page).to have_css(suggestion, text: "Nashville, TN")
    # Clear (x) becomes visible once the box has a value.
    expect(page).not_to have_css("[data-geolocation-target='clearButton'].hidden")
  end

  it "geocodes typed free text and searches on Enter" do
    location_input.send_keys("Nashville")
    # Let the typeahead settle (as a real user pauses) before pressing Enter; the
    # suggestion is present but NOT highlighted, so this exercises the free-text path.
    expect(page).to have_css(suggestion)
    location_input.send_keys(:enter)

    # Longer wait: server geocode + Turbo form submission + search render round-trip.
    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)
  end

  it "searches when a suggestion is clicked" do
    location_input.send_keys("Nash")
    find(suggestion, text: "Nashville, TN").click

    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)
  end

  it "clears the visible text but falls back to a nationwide 'Search all' filter" do
    location_input.send_keys("Nashville")
    clear_button.click

    expect(location_input.value).to eq("")
    expect(find("input[data-geolocation-target='formLatitude']", visible: :all).value).to eq(SEARCH_ALL_LAT)
    expect(find("input[data-geolocation-target='formLongitude']", visible: :all).value).to eq(SEARCH_ALL_LON)
  end
end
