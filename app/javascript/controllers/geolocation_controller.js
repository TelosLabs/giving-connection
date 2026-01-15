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
  static targets = [ "currentLocation", "formLatitude", "formLongitude" ]

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

  updateCityAndForm() {
    this.currentLocationTargets.forEach(target => target.innerText = this.currentCity);
    if (this.hasFormLatitudeTarget && this.hasFormLongitudeTarget) {
      this.formLongitudeTarget.value = this.longitude;
      this.formLatitudeTarget.value = this.latitude;
    }

    // Dispatch a custom event indicating the location has changed
    const event = new CustomEvent('location-updated', {
      detail: { latitude: this.latitude, longitude: this.longitude }
    });
    window.dispatchEvent(event);
  }
}
