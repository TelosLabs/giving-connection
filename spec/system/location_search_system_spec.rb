require "system_helper"

# Exercises the location typeahead on the home hero search bar (geolocation_controller).
# The Google Maps SDK is stubbed in-browser so these tests are deterministic and
# offline: the controller reads `google.maps.*` at call time, so defining
# `window.google` after `visit` is enough. This also guards the P1 regression where
# the body-level controller resolved `currentLocation` to the navbar <p> and threw
# on every keystroke — if that regressed, no suggestions would render.
RSpec.describe "Location search", type: :system do
  let!(:user) { create(:user) }

  # Search-all (nationwide) preset coordinates, mirrored from the controller.
  SEARCH_ALL_LAT = "37.0902".freeze
  SEARCH_ALL_LON = "-95.7129".freeze

  # Fake Google Maps SDK: a predictable autocomplete + geocoder. Served in place of
  # the real SDK (which needs an API key + network) so these tests are deterministic.
  GOOGLE_MAPS_STUB_JS = <<~JS.freeze
    (function () {
      var loc = function (lat, lng) { return { lat: function () { return lat; }, lng: function () { return lng; } }; };
      var result = {
        geometry: { location: loc(36.16404968727089, -86.78125827725053) },
        address_components: [
          { long_name: "Nashville", short_name: "Nashville", types: ["locality"] },
          { long_name: "Tennessee", short_name: "TN", types: ["administrative_area_level_1"] }
        ]
      };
      window.google = {
        maps: {
          places: {
            PlacesServiceStatus: { OK: "OK", ZERO_RESULTS: "ZERO_RESULTS" },
            AutocompleteService: function () {
              this.getPlacePredictions = function (request, callback) {
                callback([{ description: "Nashville, TN, USA", place_id: "nashville-place-id" }], "OK");
              };
            }
          },
          Geocoder: function () {
            this.geocode = function (request) { return Promise.resolve({ results: [result] }); };
          }
        }
      };
      // The layout loads the SDK with `&callback=initMap`; honor it if present.
      if (typeof window.initMap === "function") { window.initMap(); }
    })();
  JS

  let(:location_input) { find("input[data-geolocation-target='currentLocation']") }
  let(:clear_button) { find("[data-geolocation-target='clearButton']", visible: :all) }

  before do
    # Fulfill the Google Maps SDK request with our stub so the page never hits the
    # network (no hang, no key needed) and our fake `google` stays authoritative.
    browser = page.driver.browser
    # Only intercept the Maps SDK URL — leave every other request untouched so the
    # page load isn't stalled waiting for us to continue unrelated requests.
    browser.network.intercept(pattern: "*maps.googleapis.com*")
    browser.on(:request) do |request|
      if request.url.include?("maps.googleapis.com")
        request.respond(body: GOOGLE_MAPS_STUB_JS, content_type: "text/javascript")
      else
        request.continue
      end
    end

    sign_in user
    visit root_path
    # Re-apply in case the SDK script tag executed before `google` was defined.
    page.execute_script(GOOGLE_MAPS_STUB_JS)
  end

  it "renders live city suggestions as the user types (regression: no crash on keystroke)" do
    location_input.send_keys("Nash")

    expect(page).to have_css("[data-geolocation-target='suggestions'] li", text: "Nashville, TN")
    # Clear (x) becomes visible once the box has a value.
    expect(page).not_to have_css("[data-geolocation-target='clearButton'].hidden")
  end

  it "geocodes a typed location and searches on Enter" do
    location_input.send_keys("Nashville", :enter)

    # Longer wait: geocode + Turbo form submission + search render is a full round-trip.
    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)
  end

  it "searches when a suggestion is clicked" do
    location_input.send_keys("Nash")
    find("[data-geolocation-target='suggestions'] li", text: "Nashville, TN").click

    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)
  end

  it "clears the visible text but falls back to a nationwide 'Search all' filter" do
    location_input.send_keys("Nashville")
    clear_button.click

    expect(location_input.value).to eq("")
    # Presets are shown again, suggestions hidden.
    expect(page).to have_css("[data-geolocation-target='presets']", visible: true)
    # Hidden filter fields reset to the nationwide coordinates.
    expect(find("input[data-geolocation-target='formLatitude']", visible: :all).value).to eq(SEARCH_ALL_LAT)
    expect(find("input[data-geolocation-target='formLongitude']", visible: :all).value).to eq(SEARCH_ALL_LON)
  end
end
