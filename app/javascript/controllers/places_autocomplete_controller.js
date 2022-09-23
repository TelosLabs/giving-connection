import PlacesAutocomplete from 'stimulus-places-autocomplete'

export default class extends PlacesAutocomplete {
  connect() {
    super.connect()
    console.log('PlacesAutocompleteController#connect')

    // The google.maps.places.Autocomplete instance.
    this.autocomplete
  }

  // You can override the `initAutocomplete` method here.
  initAutocomplete() {
    super.initAutocomplete()
  }

  // You can override the `placeChanged` method here.
  placeChanged() {
    super.placeChanged()
    this.submitSearchForm()
  }

  submitSearchForm(){
    let form = document.getElementById('search-form')
    if (form) {
      form.submit()
    }
  }

  // You can set the Autocomplete options in this getter.
  get autocompleteOptions() {
    return {
      fields: ['address_components', 'geometry'],
      types: ['(cities)'],
      componentRestrictions: {
        country: this.countryValue
      }
    }
  }

  async askForGeoPermissions(event){
    if (navigator.geolocation) {
      document.getElementById('search_submit').disabled = true
      await navigator.geolocation.getCurrentPosition((position) => {
        console.log(position.coords)
        if (this.hasLongitudeTarget) this.longitudeTarget.value = position.coords.longitude.toString()
        if (this.hasLatitudeTarget) this.latitudeTarget.value = position.coords.latitude.toString()
        this.reverseGeocode()
        document.getElementById('search_submit').disabled = false
      })

    } else {
      console.log('Geolocation is not supported by your browser');
    }
  }

  reverseGeocode() {
    const geocoder = new google.maps.Geocoder()
    const latlng = { lat: parseFloat(this.latitudeTarget.value), lng: parseFloat(this.longitudeTarget.value) }
    const request = {
      location: latlng,
      componentRestrictions: {
        // country: "US"
      }
    }
    geocoder.geocode(request)
    .then((response) => {
      if (response.results[0]) {
        console.log(response.results[0])
        this.autocomplete.set('place', { address_components: response.results[0].address_components, formatted_address: response.results[0].address_formatted })

      } else {
        console.log("No results found");
      }
    })
    .catch((e) => console.log("Geocoder failed due to: " + e));
  }
}
