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

// NOTE ON CLIENT-SIDE RENDERING: the live city suggestions below are built in JS
// (createElement) rather than via Turbo Streams. This is an intentional exception
// to the "Stimulus never generates DOM" standard: Google Places predictions only
// exist client-side, and per-keystroke server round-trips would add latency and
// Google API cost. Rendering the *typeahead list* is the only DOM this controller
// creates; everything else routes through server-rendered markup.
export default class extends Controller {
  static targets = [ "currentLocation", "formLatitude", "formLongitude", "suggestions", "presets", "clearButton" ]

  connect() {
    useCookies(this)
    this.latitude = this.getCookie("latitude")
    this.longitude = this.getCookie("longitude")
    this.currentCity = this.getCookie("city")
  }

  disconnect() {
    // Cancel any pending debounce so a scheduled fetch can't fire against
    // recycled DOM after Turbo navigation / controller teardown.
    clearTimeout(this.suggestTimeout)
  }

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

  // Geocode a typed city name or ZIP code into coordinates, then search.
  async geocodeAndSearch(event) {
    event.preventDefault();
    if (this.isGeocoding) return; // guard against OS key-repeat / rapid Enter
    const input = event.target;
    const query = input.value.trim();
    const form = input.closest("form");
    if (!query) return;

    if (!window.google?.maps) {
      window.alert("Location search is still loading. Please try again in a moment.");
      return;
    }

    this.isGeocoding = true;
    try {
      const geocoder = new google.maps.Geocoder();
      const response = await geocoder.geocode({
        address: query,
        componentRestrictions: { country: "US" }
      });
      const result = response.results[0];
      if (!result) {
        window.alert("We couldn't find that location. Try a city name or ZIP code.");
        return;
      }

      this.applyGeocodeResult(result, this.cityFromGeocode(result) || query, form);
    } catch (error) {
      console.warn("Failed to geocode typed location:", error);
      window.alert("We couldn't look up that location. Please try again.");
    } finally {
      this.isGeocoding = false;
    }
  }

  // Shared tail for the typed-Enter and click-suggestion paths: persist the
  // resolved coordinates, sync the form fields, and submit. We submit the form
  // directly (rather than dispatching `location-updated`) because these are
  // explicit "search now" actions that must work on pages without a search
  // controller, e.g. the home hero. On the results page this is equivalent:
  // handleLocationUpdate just calls form.requestSubmit().
  applyGeocodeResult(result, cityLabel, form) {
    const coords = result.geometry.location;
    this.latitude = coords.lat();
    this.longitude = coords.lng();
    this.currentCity = cityLabel;
    this.rememberLocation();
    this.updateFormFields();
    if (form) form.requestSubmit();
  }

  cityFromGeocode(result) {
    const components = result.address_components || [];
    const find = (type) => components.find((component) => component.types.includes(type));
    const locality = find("locality") || find("postal_town") || find("sublocality");
    if (locality) return locality.long_name;

    const postal = find("postal_code");
    const state = find("administrative_area_level_1");
    if (postal) return state ? `${postal.long_name}, ${state.short_name}` : postal.long_name;
    if (state) return state.long_name;
    return null;
  }

  // Live US-city suggestions rendered into the location dropdown as the user types.
  suggestCities(event) {
    const input = event.target;
    const query = input.value.trim();
    clearTimeout(this.suggestTimeout);
    this.toggleClearButton(input);
    if (!query) {
      this.showPresets(input);
      return;
    }
    // Tag each request so a late/out-of-order response can be discarded.
    const requestId = (this.activeRequestId = (this.activeRequestId || 0) + 1);
    this.suggestTimeout = setTimeout(() => this.fetchPredictions(query, input, requestId), 150);
  }

  // Drop the trailing country ("Nashville, TN, USA" -> "Nashville, TN").
  formatCityLabel(text) {
    return text.replace(/,?\s*(USA|United States)$/i, "").trim();
  }

  // Resolve the dropdown wrapper and its scoped elements from the active input.
  // The geolocation controller lives on <body>, so multiple currentLocation
  // targets exist (navbar/pills <p> + the search-bar <input>). We must operate on
  // the element that fired the event, never the singular `...Target` (which
  // resolves to the FIRST match in the DOM — the navbar <p>).
  wrapperFor(input) {
    return input?.closest("[data-controller~='dropdown']");
  }

  elementFor(input, name) {
    return this.wrapperFor(input)?.querySelector(`[data-geolocation-target='${name}']`);
  }

  toggleClearButton(input) {
    const clearButton = this.elementFor(input, "clearButton");
    if (!clearButton) return;
    const hasValue = !!input && input.value.trim() !== "";
    clearButton.classList.toggle("hidden", !hasValue);
  }

  clearLocationInput(event) {
    event.preventDefault();
    // Cancel any pending suggestion fetch so it can't re-render for erased text.
    clearTimeout(this.suggestTimeout);
    this.activeRequestId = (this.activeRequestId || 0) + 1;

    const input = this.elementFor(event.currentTarget, "currentLocation");
    if (input) {
      input.value = "";
      // Defer focus so it lands after the click finishes bubbling.
      requestAnimationFrame(() => input.focus());
    }
    // Frontend: clear the visible text only so the user can type a new location.
    // Filter: fall back to nationwide "Search all" (hidden fields + cookies) so
    // leaving the box empty searches everywhere instead of the stale location.
    this.resetToSearchAll();
    this.showPresets(input);
    this.toggleClearButton(input);
  }

  // Reset the underlying location filter to the nationwide "Search all" preset
  // WITHOUT writing "Search all" into the visible input (kept blank for typing).
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

  fetchPredictions(query, input, requestId) {
    // The Maps SDK loads async; Places may be undefined right after page load or
    // if an extension blocks it. Fall back to presets instead of crashing.
    if (!window.google?.maps?.places) {
      console.warn("Google Places unavailable; showing preset cities.");
      this.showPresets(input);
      return;
    }

    try {
      if (!this.autocompleteService) {
        this.autocompleteService = new google.maps.places.AutocompleteService();
      }
      this.autocompleteService.getPlacePredictions(
        {
          input: query,
          types: ["(cities)"],
          componentRestrictions: { country: "us" }
        },
        (predictions, status) => {
          // Discard stale/out-of-order responses: the user has typed again or
          // cleared the box since this request was issued.
          if (requestId !== this.activeRequestId || !input || input.value.trim() !== query) return;

          const { OK, ZERO_RESULTS } = google.maps.places.PlacesServiceStatus;
          if (status === ZERO_RESULTS || !predictions || predictions.length === 0) {
            this.showPresets(input);
            return;
          }
          if (status !== OK) {
            // Quota/billing/key failure — distinct from "no matches" for debugging.
            console.warn("City autocomplete error status:", status);
            this.showPresets(input);
            return;
          }
          this.renderPredictions(predictions, input);
        }
      );
    } catch (error) {
      console.warn("City autocomplete failed:", error);
      this.showPresets(input);
    }
  }

  // Ensure the location dropdown for the active input is open so suggestions show.
  openDropdown(input) {
    const el = this.wrapperFor(input);
    if (!el) return;
    const controller = this.application.getControllerForElementAndIdentifier(el, "dropdown");
    if (controller && typeof controller.show === "function") controller.show();
  }

  renderPredictions(predictions, input) {
    const suggestions = this.elementFor(input, "suggestions");
    const presets = this.elementFor(input, "presets");
    if (!suggestions) return;

    suggestions.innerHTML = "";
    predictions.forEach(prediction => {
      const item = document.createElement("li");
      item.className = "block px-4 py-2 cursor-pointer text-gray-3 hover:bg-seafoam";
      item.textContent = this.formatCityLabel(prediction.description);
      item.dataset.placeId = prediction.place_id;
      item.dataset.action = "click->dropdown#toggle click->geolocation#selectPrediction";
      suggestions.appendChild(item);
    });

    suggestions.classList.remove("hidden");
    if (presets) presets.classList.add("hidden");
    this.openDropdown(input);
  }

  showPresets(input) {
    const suggestions = this.elementFor(input, "suggestions");
    const presets = this.elementFor(input, "presets");
    if (suggestions) {
      suggestions.innerHTML = "";
      suggestions.classList.add("hidden");
    }
    if (presets) presets.classList.remove("hidden");
  }

  async selectPrediction(event) {
    const li = event.currentTarget;
    const placeId = li.dataset.placeId;
    const description = li.textContent.trim();
    const form = li.closest("form");
    const input = this.elementFor(li, "currentLocation");
    if (!placeId) return;

    if (!window.google?.maps) {
      window.alert("Location search is still loading. Please try again in a moment.");
      return;
    }

    try {
      const geocoder = new google.maps.Geocoder();
      const response = await geocoder.geocode({ placeId });
      const result = response.results[0];
      if (!result) {
        window.alert("We couldn't load that location. Please try another.");
        return;
      }

      this.applyGeocodeResult(result, description, form);
      this.showPresets(input);
    } catch (error) {
      console.warn("Failed to resolve selected city:", error);
      window.alert("We couldn't load that location. Please try again.");
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

  rememberLocation() {
    this.setCookie("latitude", this.latitude)
    this.setCookie("longitude", this.longitude)
    this.setCookie("city", this.currentCity)
  }

  updateLocation(event) {
    this.currentCity = event.target.innerText
    this.latitude = CITIES[this.currentCity].latitude
    this.longitude = CITIES[this.currentCity].longitude
    this.rememberLocation()
    this.updateCityAndForm()
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
