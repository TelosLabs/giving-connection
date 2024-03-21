import { Controller } from "@hotwired/stimulus";

  const options = {
    enableHighAccuracy: true,
    timeout: 5000,
    maximumAge: 0
  };

export default class extends Controller { 
  static targets = [ "currentLocation" ]

  connect() {
    this.currentCity = this.currentLocationTarget.innerText
  }

  async success(position) {
    let city;
    const coordinates = position.coords;
    document.cookie = `latitude=${coordinates.latitude}`;
    document.cookie = `longitude=${coordinates.longitude}`;
    city = await this.findNearestCity(coordinates)
    this.updateNavbarLocation(city);
  }

  async findNearestCity(coordinates) {
    let response;
    const geocoder = new google.maps.Geocoder()
    const coords= { lat: coordinates.latitude, lng: coordinates.longitude }
    response = await geocoder.geocode({ location: coords })
    if (response.results[0]) {
      this.currentCity = response.results[0].address_components[3].long_name
      document.cookie = `city=${this.currentCity}`;
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

  updateNavbarLocation() {
    this.currentLocationTarget.innerText = this.currentCity 
  }
}