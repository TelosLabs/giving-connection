import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field", "map", "latitude", "longitude", "marker" ]
  static values = {
    imageurl: String,
    clickedimageurl: String,
    zoom: { type: Number, default: 10 },
    latitude: Number,
    longitude: Number,
  }

  connect() {
    if (typeof(google) != "undefined") {
      this.initMap()
    }
  }

  initialize() {
    this.markersArray = []
    this.mapMarkers = []
    this.image = this.imageurlValue
    this.clickedImage = this.clickedimageurlValue
    this.searchResultTitles = document.querySelectorAll('[id^="new_favorite"]');
    this.setSearchResultsListeners()
  }

  setSearchResultsListeners() {
    if (this.searchResultTitles) {
      this.searchResultTitles.forEach((node) => {
        node.addEventListener('click', this.showPopup.bind(this))
      })
    }
  }

  showPopup(event) {
    let container = document.getElementById('left-popup')
    container.childNodes.forEach((node) => {
      node.classList.add('hidden')
      let node_id = node.id.replace(/\D/g, '');
      let event_id = event.target.id.replace(/\D/g, '');
      if (node_id == event_id) {
        node.classList.remove('hidden')
      }
      this.mapMarkers.forEach((marker) => {
        marker.setIcon(this.image)
        marker.setAnimation(null);
        if (marker.id == event_id) {
          marker.setIcon(this.clickedImage)
          marker.setAnimation(google.maps.Animation.BOUNCE);
        }
      })
    })
  }

  hidePopup() {
    let container = document.getElementById('left-popup')
    container.childNodes.forEach((node) => {
      node.classList.add('hidden')
    })
    this.mapMarkers.forEach((marker) => {
      marker.setAnimation(null);
      marker.setIcon(this.image)
    })
  }

  scrollToSelectedLocation(){
    if(sessionStorage.getItem('hovered_location_id')) {
      let id = sessionStorage.getItem('hovered_location_id').split('_')[1]
      let card = document.getElementById(id)
      card.scrollIntoView({behavior: 'smooth', block: "nearest", inline: "nearest"})
    }
  }

  initMap() {
    this.map = new google.maps.Map(this.mapTarget, {
      center: new google.maps.LatLng(this.latitudeValue || Number(this.latitudeTarget.value) || 36.16404968727089, this.longitudeValue || Number(this.longitudeTarget.value) || -86.78125827725053),
      zoom: (this.zoomValue || 10),
      mapTypeControl: true,
      mapTypeControlOptions: {
        style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
        position: google.maps.ControlPosition.TOP_CENTER
      }
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
    const clickedImage = this.clickedimageurlValue

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
      this.setMarkers(this.map, image, clickedImage);
    }else{
      this.marker = new google.maps.Marker({
        map: this.map,
        anchorPoint: new google.maps.Point(0, -29),
        icon: image
      })
    }

    let clickedLocation = document.getElementById(sessionStorage.getItem('clicked_location_id'))
    let selectedMarker = sessionStorage.getItem('selected_marker')
    if (clickedLocation) {
      clickedLocation.classList.remove('hidden')
    }
    if (selectedMarker) {
      this.mapMarkers.forEach((marker) => {
        if (marker.id == selectedMarker) {
          marker.setIcon(clickedImage)
        }
      })
    }
  }

  setMarkers(map, image, clickedImage) {
    // Adds markers to the map.
    let prevInfoWindow = false
    let pin = document.getElementById(sessionStorage.getItem('hovered_location_id'))

    for (let i = 0; i < this.markerTargets.length; i++) {
      const element = this.markerTargets[i];
      const latitudeTarget = Number(element.dataset.latitude)
      const longitudeTarget = Number(element.dataset.longitude)
      const element_id = element.id.replace(/\D/g, '');

      const marker = new google.maps.Marker({
        position: { lat: latitudeTarget, lng: longitudeTarget },
        map: map,
        icon: image,
        animation: google.maps.Animation.DROP,
        id: element_id
      });

      this.mapMarkers.push(marker)

      const infowindow = new google.maps.InfoWindow({
        content: this.markerTargets[i],
        maxWidth: 210,
      });

      marker.addListener("click", () => {
        let container = document.getElementById('left-popup')
        this.mapMarkers.forEach((marker) => {
          marker.setIcon(image)
          marker.setAnimation(null);
        })
        container.childNodes.forEach((node) => {
          node.classList.add('hidden')
          let node_id = node.id.replace(/\D/g, '');
          if (node_id == element_id) {
            node.classList.remove('hidden')
            marker.setIcon(clickedImage)
            sessionStorage.setItem('clicked_location_id', node.id)
            sessionStorage.setItem('selected_marker', marker.id)
          }
        })
      })


      marker.addListener("mouseover", () => {
        if( prevInfoWindow ) {
          prevInfoWindow.close()
        }
        marker.setAnimation(null);

        prevInfoWindow = infowindow

        infowindow.open({
          anchor: marker,
          map,
          shouldFocus: false,
        });

        sessionStorage.setItem('hovered_location_id', element.id)
        this.scrollToSelectedLocation()
      });

      if (pin && pin.id == element.id)  {
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
