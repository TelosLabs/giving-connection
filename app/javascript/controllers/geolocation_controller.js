import { Controller } from "@hotwired/stimulus";

  const options = {
    enableHighAccuracy: true,
    timeout: 5000,
    maximumAge: 0
  };

  const CITIES = {
    "Nashville" : { latitude: 36.1627, longitude: -86.7816 },
    "Atlantic City" : { latitude: 39.3643, longitude: -74.4229 },
  }
export default class extends Controller { 
  static targets = [ "currentLocation", "formLatitude", "formLongitude" ]

  connect() {
    this.latitude = this.findInCookie("latitude")
    this.longitude = this.findInCookie("longitude")
    this.currentCity = this.findInCookie("city")
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
    this.updateDOM()
  }

  error(err) {
    console.warn(`ERROR(${err.code}): ${err.message}`)
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
    document.cookie = `latitude=${this.latitude}`
    document.cookie = `longitude=${this.longitude}`
    document.cookie = `city=${this.currentCity}`
  }

  updateCity() {
    for (let target of this.currentLocationTargets) {
      target.innerText = this.currentCity
    }
  }

  updateLocation(event) {
    this.currentCity = event.target.innerText
    this.latitude = CITIES[this.currentCity].latitude
    this.longitude = CITIES[this.currentCity].longitude
    this.rememberLocation()
    this.updateDOM()
  }

  updateForm() {
    this.formLongitudeTarget.value = this.longitude
    this.formLatitudeTarget.value = this.latitude
  }

  updateDOM() {
    this.updateCity()
    this.updateForm()
  }

  findInCookie(key) {
    document.cookie?.split('; ')?.find(row => row.startsWith(`${key}=`))?.split('=')[1] || null
  }
}
