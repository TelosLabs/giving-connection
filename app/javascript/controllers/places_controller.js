import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field", "map", "latitude", "longitude", "marker", "location" ]
  static values = {
    imageurl: String,
    zoom: { type: Number, default: 10 },
    latitude: Number,
    longitude: Number,
    markers: Array,
  }

  connect() {
    if (typeof(google) != "undefined") {
      this.initMap()
    }
  }

  initialize() {
    this.markersArray = []
    if(sessionStorage.getItem('location_id')) {
      let id = sessionStorage.getItem('location_id').split('_')[1]
      let card = document.getElementById(id)
      card.scrollIntoView({behavior: 'smooth'})
    }
  }

  initMap() {
    this.map = new google.maps.Map(this.mapTarget, {
      center: new google.maps.LatLng(this.latitudeValue || Number(this.latitudeTarget.value) || 36.16404968727089, this.longitudeValue || Number(this.longitudeTarget.value) || -86.78125827725053),
      zoom: (this.zoomValue || 10)
    })

    function success (position) {
       document.getElementById('search_lat').value = position.coords.latitude;
       document.getElementById('search_lon').value = position.coords.longitude;
     }

    if(!navigator.geolocation) {
       console.log('Geolocation is not supported by your browser');
     } else {
       navigator.geolocation.getCurrentPosition(success);
     }
    
    const image = this.imageurlValue

    if (this.hasFieldTarget) {
      this.autocomplete = new google.maps.places.Autocomplete(this.fieldTarget)
      this.autocomplete.bindTo('bounds', this.map)
      this.autocomplete.setFields(['address_components', 'geometry', 'icon', 'name'])
      this.autocomplete.addListener('place_changed', this.placeChanged.bind(this))
      
      this.marker = new google.maps.Marker({
        position: { lat: Number(this.latitudeTarget.value) , lng: Number(this.longitudeTarget.value) },
        map: this.map,
        icon: image
      });
      this.markersArray.push(this.marker)
    }

    if (this.hasMarkerTarget) {
      this.setMarkers(this.map, image);
    }else{
      this.marker = new google.maps.Marker({
        map: this.map,
        anchorPoint: new google.maps.Point(0, -29),
        icon: image
      })
    }
  }

  setMarkers(map, image) {
    // Adds markers to the map.
    let prevInfoWindow = false
    let pin = document.getElementById(sessionStorage.getItem('location_id'))

    for (let i = 0; i < this.markerTargets.length; i++) {
      const element = this.markerTargets[i];
      const latitudeTarget = Number(element.dataset.latitude)
      const longitudeTarget = Number(element.dataset.longitude)

      const marker = new google.maps.Marker({
        position: { lat: latitudeTarget, lng: longitudeTarget },
        map: map,
        icon: image
      });

      const infowindow = new google.maps.InfoWindow({
        content: this.markerTargets[i],
        maxWidth: 210,
      });

      marker.addListener("click", () => {
        if( prevInfoWindow ) {
          prevInfoWindow.close()
        }

        prevInfoWindow = infowindow

        infowindow.open({
          anchor: marker,
          map,
          shouldFocus: false,
        });

        sessionStorage.setItem('location_id', element.id)
      });

     if( pin && pin.id == element.id ) {
       prevInfoWindow = infowindow
       infowindow.open({
         anchor: marker,
         map,
         shouldFocus: false,
       });
     }
    }
  }

  placeChanged() {
    this.clearMarkers()
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

  clearMarkers() {
    for (var i = 0; i < this.markersArray.length; i++ ) {
      this.markersArray[i].setMap(null);
    }
    this.markersArray.length = 0;
  }
}
