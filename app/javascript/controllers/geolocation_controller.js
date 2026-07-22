import { Controller } from "@hotwired/stimulus";
import { useCookies } from "./mixins/useCookies";

  const options = {
    enableHighAccuracy: true,
    timeout: 5000,
    maximumAge: 0
  };

  const CITIES = {
    "Nashville" : { latitude: 36.16404968727089, longitude: -86.78125827725053 },
    "Atlantic City" : { latitude: 39.3625, longitude: -74.425 },
    "Search all": { latitude: 37.0902, longitude: -95.7129 },
    "Los Angeles": { latitude: 34.0522, longitude: -118.2437 },
  }

  const IP_LOOKUP_COOLDOWN_MS = 12 * 60 * 60 * 1000; // 12 hours in miliseconds (12h * 60m * 60s * 1000ms)

// This controller owns the "where am I" concerns of the search bar: browser
// geolocation + IP fallback, preset cities ("Search near me"), cookie
// persistence, and syncing the resolved location into the form.
//
// The live city typeahead is handled by the `stimulus-autocomplete` controller
// (server-rendered predictions from LocationSearchesController), NOT here. When a
// suggestion is picked or free text is submitted, we resolve it to coordinates
// via the server geocode endpoint and submit — no client-side Google calls.
export default class extends Controller {
  static targets = [ "currentLocation", "formLatitude", "formLongitude", "presets", "clearButton" ]

  connect() {
    useCookies(this)
    this.latitude = this.getCookie("latitude")
    this.longitude = this.getCookie("longitude")
    this.currentCity = this.getCookie("city")
  }

  // --- Browser geolocation / IP fallback (the "Search near me" preset) ---

  async getCurrentPosition() {
    navigator.geolocation.getCurrentPosition(this.success.bind(this), this.error.bind(this), options);
  }

  async applyLocation(coordinates, city = null) {
    this.latitude = coordinates.latitude;
    this.longitude = coordinates.longitude;
    this.currentCity = city ? city : await this.findNearestCity(coordinates);
    this.rememberLocation();
    this.updateCityAndForm();
  }

  async success(position) {
    const coordinates = position.coords;
    await this.applyLocation(coordinates);
  }

  async error(err) {
    if (err.code === 1) {
      // User denied access to location services
      console.warn(`ERROR(${err.code}): ${err.message}`)
      window.alert('Please enable location services to use this feature. Visit your browser settings to enable location services.')
    }
    await this.getLocationFromIP();
  }

  async applySearchAllFallback() {
    const coordinates = CITIES["Search all"];
    const city = "Search all";
    await this.applyLocation(coordinates, city);
  }

  canUseIPLookup() {
    const lastLookup = this.getCookie("last_ip_lookup_at");
    if (!lastLookup) return true;

    return (Date.now() - parseInt(lastLookup, 10)) > IP_LOOKUP_COOLDOWN_MS;
  }

  async getLocationFromIP() {
    if (!this.canUseIPLookup()) {
      console.warn("Skipping IP lookup due to rate limiting");

      if (this.latitude && this.longitude && this.currentCity) {
        this.updateCityAndForm();
      } else {
        await this.applySearchAllFallback();
      }
      return;
    }

    try {
      const response = await fetch("https://ipapi.co/json/");

      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }

      const locationData = await response.json();
      const coordinates = { latitude: locationData.latitude, longitude: locationData.longitude }
      this.setCookie("last_ip_lookup_at", Date.now());
      await this.applyLocation(coordinates, locationData.city);
    } catch (error) {
      console.warn("Failed to fetch location via IP:", error);
      await this.applySearchAllFallback();
    }
  }

  async findNearestCity(coordinates) {
    let response;
    const geocoder = new google.maps.Geocoder()
    const coords= { lat: coordinates.latitude, lng: coordinates.longitude }
    response = await geocoder.geocode({ location: coords })
    if (response.results[0]) {
     return response.results[0].address_components[3].long_name
    } else {
      console.warning('No location found');
    }
  }

  // --- Preset cities ---

  updateLocation(event) {
    this.currentCity = event.target.innerText
    this.latitude = CITIES[this.currentCity].latitude
    this.longitude = CITIES[this.currentCity].longitude
    this.rememberLocation()
    this.updateCityAndForm()
  }

  // --- Typeahead selection (driven by the stimulus-autocomplete controller) ---

  // Fired via `autocomplete.change` when the user picks a suggestion. Resolve the
  // chosen city label to coordinates server-side, then search.
  async locationSelected(event) {
    const query = event.detail && event.detail.value;
    const form = event.target.closest("form");
    if (!query) return;

    const location = await this.geocode(query);
    if (!location) {
      window.alert("We couldn't load that location. Please try again.");
      return;
    }
    this.applyResolved(location, form);
  }

  // Fired on Enter for free text that wasn't picked from the suggestion list.
  async searchTyped(event) {
    // If a suggestion is highlighted, let stimulus-autocomplete commit it (its
    // Enter handler fires autocomplete.change -> locationSelected). Bail so we
    // don't geocode + submit twice.
    const results = event.target
      .closest("[data-controller~='autocomplete']")
      ?.querySelector("[data-autocomplete-target='results']");
    if (results && !results.hidden && results.querySelector('[aria-selected="true"]')) return;

    event.preventDefault();
    if (this.isGeocoding) return; // guard OS key-repeat / rapid Enter
    const input = event.target;
    const query = input.value.trim();
    const form = input.closest("form");
    if (!query) return;

    this.isGeocoding = true;
    try {
      const location = await this.geocode(query);
      if (!location) {
        window.alert("We couldn't find that location. Try a city name or ZIP code.");
        return;
      }
      this.applyResolved(location, form);
    } finally {
      this.isGeocoding = false;
    }
  }

  // Resolve a typed/selected string to { latitude, longitude, city } via the
  // server geocode endpoint. Returns null on any failure.
  async geocode(query) {
    try {
      const url = new URL("/location_search/geocode", window.location.origin);
      url.searchParams.set("q", query);
      const response = await fetch(url, { headers: { Accept: "application/json" } });
      if (!response.ok) return null;
      return await response.json();
    } catch (error) {
      console.warn("Failed to geocode location:", error);
      return null;
    }
  }

  applyResolved(location, form) {
    this.latitude = location.latitude;
    this.longitude = location.longitude;
    this.currentCity = location.city;
    this.rememberLocation();
    this.updateFormFields();
    if (form) form.requestSubmit();
  }

  // --- Clear button + preset/suggestion visibility ---

  // Bound to the input's `input` event: show the clear (x) only when non-empty.
  onInput(event) {
    if (!this.hasClearButtonTarget) return;
    this.clearButtonTarget.classList.toggle("hidden", event.target.value.trim() === "");
  }

  // Bound to the autocomplete `toggle` event: hide presets while suggestions are
  // open, show them again when the suggestion list closes.
  onAutocompleteToggle(event) {
    if (!this.hasPresetsTarget) return;
    const open = event.detail && event.detail.action === "open";
    this.presetsTarget.classList.toggle("hidden", open);
  }

  clearLocationInput(event) {
    event.preventDefault();
    const input = event.currentTarget
      .closest("[data-controller~='dropdown']")
      ?.querySelector("[data-geolocation-target='currentLocation']");
    if (input) {
      input.value = "";
      // Let stimulus-autocomplete clear its results (fires `toggle` -> presets show).
      input.dispatchEvent(new Event("input"));
      // Defer focus so it lands after the click finishes bubbling.
      requestAnimationFrame(() => input.focus());
    }
    // Frontend clears the visible text only; the underlying filter falls back to
    // nationwide "Search all" so an empty box searches everywhere, not the stale
    // previous location.
    this.resetToSearchAll();
    if (this.hasClearButtonTarget) this.clearButtonTarget.classList.add("hidden");
  }

  resetToSearchAll() {
    const coords = CITIES["Search all"];
    this.latitude = coords.latitude;
    this.longitude = coords.longitude;
    this.currentCity = "Search all";
    this.rememberLocation();
    if (this.hasFormLatitudeTarget && this.hasFormLongitudeTarget) {
      this.formLatitudeTarget.value = this.latitude;
      this.formLongitudeTarget.value = this.longitude;
    }
  }

  // --- Persistence + form sync ---

  rememberLocation() {
    this.setCookie("latitude", this.latitude)
    this.setCookie("longitude", this.longitude)
    this.setCookie("city", this.currentCity)
  }

  updateFormFields() {
    this.currentLocationTargets.forEach(target => {
      if (target.tagName === "INPUT") {
        target.value = this.currentCity;
      } else {
        target.innerText = this.currentCity;
      }
    });
    if (this.hasFormLatitudeTarget && this.hasFormLongitudeTarget) {
      this.formLongitudeTarget.value = this.longitude;
      this.formLatitudeTarget.value = this.latitude;
    }
  }

  updateCityAndForm() {
    this.updateFormFields();

    // Dispatch a custom event indicating the location has changed
    const event = new CustomEvent('location-updated', {
      detail: { latitude: this.latitude, longitude: this.longitude }
    });
    window.dispatchEvent(event);
  }
}
