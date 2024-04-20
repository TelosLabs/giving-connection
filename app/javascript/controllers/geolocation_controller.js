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
    "Search all": { latitude: 37.0902, longitude: -95.7129 }
  }
export default class extends Controller { 
  static targets = [ "currentLocation", "formLatitude", "formLongitude" ]

  connect() {
    useCookies(this)
    this.latitude = this.getCookie("latitude")
    this.longitude = this.getCookie("longitude")
    this.currentCity = this.getCookie("city")
  }

  async getCurrentPosition() {
    navigator.geolocation.getCurrentPosition(this.success.bind(this), this.error, options);
  }

  async success(position) {
    const coordinates = position.coords;
    this.latitude = coordinates.latitude
    this.longitude = coordinates.longitude
    this.currentCity = await this.findNearestCity(coordinates)
    this.rememberLocation()
    this.updateCityAndForm()
  }

  error(err) {
    if (err.code === 1) {
      // User denied access to location services
      console.warn(`ERROR(${err.code}): ${err.message}`)
      window.alert('Please enable location services to use this feature. Visit your browser settings to enable location services.') 
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
    const event = new CustomEvent('locationUpdated', {
      detail: { latitude: this.latitude, longitude: this.longitude }
    });
    window.dispatchEvent(event);
  }
}
