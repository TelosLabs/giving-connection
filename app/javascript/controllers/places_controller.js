import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field", "map", "latitude", "longitude" ]
  static values = { imageurl: String }

  connect() {
    if (typeof(google) != "undefined") {
      this.initMap()
    }
  }

  initMap() {
    this.map = new google.maps.Map(this.mapTarget, {
      center: new google.maps.LatLng(this.data.get("latitude") || 36.16404968727089, this.data.get("longitude") || -86.78125827725053),
      zoom: (10)
    })

    this.autocomplete = new google.maps.places.Autocomplete(this.fieldTarget)
    this.autocomplete.bindTo('bounds', this.map)
    this.autocomplete.setFields(['address_components', 'geometry', 'icon', 'name'])
    this.autocomplete.addListener('place_changed', this.placeChanged.bind(this))

    const image = this.imageurlValue

    this.setMarkers(this.map, image);
  }

  setMarkers(map, image) {
    // Adds markers to the map.
    var pages = [
      [0.3653588e2, -0.87349923e2],
      [0.3612309e2, -0.8670337e2],
      [0.3612309e2, -0.8670337e2],
      [0.36089846e2, -0.86698857e2],
      [0.36165602e2, -0.8678218e2]
    ]

    for (let i = 0; i < pages.length; i++) {
      const page = pages[i];

      new google.maps.Marker({
        position: { lat: page[0], lng: page[1] },
        map: map,
        icon: image
      });
    }
  }

  placeChanged() {
    let place = this.autocomplete.getPlace()

    if (!place.geometry) {
      window.alert(`No details available for input: ${place.name}`)
      return
    }

    if (place.geometry.viewport) {
      this.map.fitBounds(place.geometry.viewport)
    } else {
      this.map.setCenter(place.geometry.location)
      this.map.setZoom(17)
    }

    this.marker.setPosition(place.geometry.location)
    this.marker.setVisible(true)

    this.latitudeTarget.value = place.geometry.location.lat()
    this.longitudeTarget.value = place.geometry.location.lng()
  }

  keydown(event) {
    if (event.key == "Enter") {
      event.preventDefault()
    }
  }
}
