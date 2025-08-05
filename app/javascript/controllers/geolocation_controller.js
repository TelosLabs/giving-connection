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
    this.currentCity = this.findNearestCity(coordinates)
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

  calculateDistance(coords1, coords2) {
    // Use Haversine formula for accurate distance calculating
    const R = 6371 // Earth's radius in kilometers
    const toRadians = (degrees) => degrees * (Math.PI / 180)

    const lat1 = toRadians(coords1.latitude)
    const lat2 = toRadians(coords2.latitude)
    const deltaLat = toRadians(coords2.latitude - coords1.latitude)
    const deltaLon = toRadians(coords2.longitude - coords1.longitude)

    const a =
      Math.sin(deltaLat / 2) ** 2 +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) ** 2

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    return R * c // Distance in kilometers
  }

  findNearestCity(coordinates) {
    let closestCity = "Search all" // fallback
    let minDistance = Infinity

    for (const [city, coords] of Object.entries(CITIES)) {
      const distance = this.calculateDistance(coordinates, coords)
      console.log(`Distance from ${city}:`, distance)
      if (distance < minDistance) {
        minDistance = distance
        closestCity = city
      }
    }

    return closestCity
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
