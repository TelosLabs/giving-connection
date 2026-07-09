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

export default class extends Controller { 
  static targets = [ "currentLocation", "formLatitude", "formLongitude", "suggestions", "presets", "clearButton" ]

  connect() {
    useCookies(this)
    this.latitude = this.getCookie("latitude")
    this.longitude = this.getCookie("longitude")
    this.currentCity = this.getCookie("city")
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
    const query = event.target.value.trim();
    const form = event.target.closest("form");
    if (!query) return;

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

      const coords = result.geometry.location;
      this.latitude = coords.lat();
      this.longitude = coords.lng();
      this.currentCity = this.cityFromGeocode(result) || query;
      this.rememberLocation();
      this.updateFormFields();
      if (form) form.requestSubmit();
    } catch (error) {
      console.warn("Failed to geocode typed location:", error);
      window.alert("We couldn't look up that location. Please try again.");
    }
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
    const query = event.target.value.trim();
    clearTimeout(this.suggestTimeout);
    if (!query) {
      this.showPresets();
      this.toggleClearButton();
      return;
    }
    this.suggestTimeout = setTimeout(() => this.fetchPredictions(query), 150);
    this.toggleClearButton();
  }

  // Drop the trailing country ("Nashville, TN, USA" -> "Nashville, TN").
  formatCityLabel(text) {
    return text.replace(/,?\s*(USA|United States)$/i, "").trim();
  }

  toggleClearButton() {
    if (!this.hasClearButtonTarget) return;
    const hasValue = this.hasCurrentLocationTarget && this.currentLocationTarget.value.trim() !== "";
    this.clearButtonTarget.classList.toggle("hidden", !hasValue);
  }

  clearLocationInput(event) {
    event.preventDefault();
    const wrapper = event.currentTarget.closest("[data-controller~='dropdown']");
    const input = wrapper?.querySelector("[data-geolocation-target='currentLocation']");
    if (input) {
      input.value = "";
      // Defer focus so it lands after the click finishes bubbling.
      requestAnimationFrame(() => input.focus());
    }
    this.showPresets();
    this.toggleClearButton();
  }

  fetchPredictions(query) {
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
        if (status !== google.maps.places.PlacesServiceStatus.OK || !predictions || predictions.length === 0) {
          console.warn("City autocomplete returned no predictions:", status);
          this.showPresets();
          return;
        }
        this.renderPredictions(predictions);
      }
    );
  }

  // Ensure the location dropdown is open so rendered suggestions are visible.
  openDropdown() {
    if (!this.hasCurrentLocationTarget) return;
    const el = this.currentLocationTarget.closest("[data-controller~='dropdown']");
    if (!el) return;
    const controller = this.application.getControllerForElementAndIdentifier(el, "dropdown");
    if (controller && typeof controller.show === "function") controller.show();
  }

  renderPredictions(predictions) {
    if (!this.hasSuggestionsTarget) return;

    this.suggestionsTarget.innerHTML = "";
    predictions.forEach(prediction => {
      const item = document.createElement("li");
      item.className = "block px-4 py-2 cursor-pointer text-gray-3 hover:bg-seafoam";
      item.textContent = this.formatCityLabel(prediction.description);
      item.dataset.placeId = prediction.place_id;
      item.dataset.action = "click->dropdown#toggle click->geolocation#selectPrediction";
      this.suggestionsTarget.appendChild(item);
    });

    this.suggestionsTarget.classList.remove("hidden");
    if (this.hasPresetsTarget) this.presetsTarget.classList.add("hidden");
    this.openDropdown();
  }

  showPresets() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.innerHTML = "";
      this.suggestionsTarget.classList.add("hidden");
    }
    if (this.hasPresetsTarget) this.presetsTarget.classList.remove("hidden");
  }

  async selectPrediction(event) {
    const placeId = event.currentTarget.dataset.placeId;
    const description = event.currentTarget.textContent.trim();
    const form = event.currentTarget.closest("form");
    if (!placeId) return;

    try {
      const geocoder = new google.maps.Geocoder();
      const response = await geocoder.geocode({ placeId });
      const result = response.results[0];
      if (!result) return;

      const coords = result.geometry.location;
      this.latitude = coords.lat();
      this.longitude = coords.lng();
      this.currentCity = description;
      this.rememberLocation();
      this.updateFormFields();
      this.showPresets();
      if (form) form.requestSubmit();
    } catch (error) {
      console.warn("Failed to resolve selected city:", error);
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
