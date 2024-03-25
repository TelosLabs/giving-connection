import { Controller } from "@hotwired/stimulus";

  const options = {
    enableHighAccuracy: true,
    timeout: 5000,
    maximumAge: 0
  };

export default class extends Controller { 
  static targets = [ "currentLocation", "formLatitude", "formLongitude" ]

  connect() {
    this.latitude = this.findInCookie("latitude")
    this.longitude = this.findInCookie("longitude")
    this.currentCity = this.findInCookie("city")
  }

  async success(position) {
    const coordinates = position.coords;
    document.cookie = `latitude=${coordinates.latitude}`;
    document.cookie = `longitude=${coordinates.longitude}`;
    this.latitude = coordinates.latitude
    this.longitude = coordinates.longitude
    this.currentCity = await this.findNearestCity(coordinates)
    this.rememberLocation()
    this.updateNavbarLocation();
    this.updateForm()
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

  error(err) {
    console.warn(`ERROR(${err.code}): ${err.message}`)
  }

  async getCurrentPosition() {
    navigator.geolocation.getCurrentPosition(this.success.bind(this), this.error, options);
  }

  rememberLocation() {
    document.cookie = `latitude=${this.latitude}`
    document.cookie = `longitude=${this.longitude}`
    document.cookie = `city=${this.currentCity}`
  }

  updateNavbarLocation() {
    this.currentLocationTarget.innerText = this.currentCity
  }

  updateLocation(event) {
    this.currentCity = event.target.innerText
    this.rememberLocation()
    this.updateNavbarLocation()
    this.updateForm()
  }

  updateForm() {
    this.formLongitudeTarget.value = this.longitude
    this.formLatitudeTarget.value = this.latitude
  }

  findInCookie(key) {
    document.cookie?.split('; ')?.find(row => row.startsWith(`${key}=`))?.split('=')[1] || null
  }
}
