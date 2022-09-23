import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field", "map", "latitude", "longitude", "marker", "geo", "lat", "lon" ]
  static values = {
    imageurl: String,
    zoom: { type: Number, default: 10 },
    latitude: Number,
    longitude: Number,
  }

  async connect() {
    console.log(this.mapTarget)
    if (typeof(google) != "undefined") {
      await this.initMap()
    }
  }

  initialize() {
    this.markersArray = []
  }

  

  async initMap() {
    this.map = await new google.maps.Map(this.mapTarget, {
      center: new google.maps.LatLng(this.latitudeValue || Number(this.latitudeTarget.value) || 36.16404968727089, this.longitudeValue || Number(this.longitudeTarget.value) || -86.78125827725053),
      zoom: (this.zoomValue || 10)
    })

    const params = new URLSearchParams(window.location.search)

    // Get the location select input
    let location = document.getElementById("location")

    // Get hidden fields
    const latitude = document.getElementById('hidden_lat')
    const longitude = document.getElementById('hidden_lon')

    // Use previous selecction of location select if it exist, this helps to keep the current selection if the page renders
    if( params.has("search[location_search]")) {
      document.getElementById("location").value = params.get("search[location_search]")
    }

    // Get coords from location select options
    let coords = {
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude)
    }

    // Center location on the map
    if( params.has("search[lat]")) { // Using coords from the URL params instead of reload ip-lookup
      this.centerOnLocation({latitude: parseFloat(params.get("search[lat]")), longitude: parseFloat(params.get("search[lon]"))})
    }else{
      this.centerOnLocation(coords) // Using coords from ip-lookup
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

    location.addEventListener("change", async (event) => {
      switch(event.target.value) {
        case "Current Location":
          this.askForGeoPermissions(event)
              .then(() => {
                console.log("geo access granted")
              }
            );
          break
        default:
          // Get hidden fields
          const lat = document.getElementById('hidden_lat')
          const lon = document.getElementById('hidden_lon')

          // Set the hidden inputs with coords
          lat.value = event.target.options[event.target.selectedIndex].getAttribute("data-latitude");
          lon.value = event.target.options[event.target.selectedIndex].getAttribute("data-longitude");

          // Get coords from location select options
          let coords = {
            latitude: parseFloat(event.target.options[event.target.selectedIndex].getAttribute("data-latitude")),
            longitude: parseFloat(event.target.options[event.target.selectedIndex].getAttribute("data-longitude"))
          }

          // Center location on the map
          this.centerOnLocation(coords)
      }
    })
  }

  async changePosition(event){
    console.log(event)
    let latitude = event.target.options[event.target.selectedIndex].getAttribute("latitude")
    let longitude = event.target.options[event.target.selectedIndex].getAttribute("longitude")
    console.log(latitude, longitude)
    this.centerOnLocation({latitude, longitude})
    event.preventDefault()
  }

  centerOnLocation( coords ) {
    this.map.setCenter({lat: coords.latitude, lng: coords.longitude})
    this.map.setZoom(10);
  }

  setMarkers(map, image) {
    // Adds markers to the map.
    let prevInfoWindow = false
    let pin = document.getElementById(sessionStorage.getItem('selected_location_id'))

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

        sessionStorage.setItem('selected_location_id', element.id)
        this.scrollToSelectedLocation()
      });

     if( pin && pin.id == element.id) {
       prevInfoWindow = infowindow
       infowindow.open({
         anchor: marker,
         map,
         shouldFocus: false,
       });
       this.scrollToSelectedLocation()
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
