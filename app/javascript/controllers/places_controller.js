import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "field", "map", "latitude", "longitude", "marker", "popup" ]
  static values = {
    imageurl: String,
    clickedimageurl: String,
    zoom: { type: Number, default: 10 },
    latitude: Number,
    longitude: Number,
    popupUrl: String,
  }

  connect() {
    this.resetMarkers();
    this.cleanLocalStorage();

    if (typeof(google) != "undefined") {
      this.initMap()
    }
  }

  initialize() {
    this.markersArray = []
    this.mapMarkers = []
    this.image = this.imageurlValue
    this.clickedImage = this.clickedimageurlValue
  }

  reloadPage() {
    window.location.search = window.location.search
  }

  // Left map popup functions start here
  // It was necessary to create this functions in this controller because the map is created here, and we have access to Markers.

  openPopupAndMarker(event) {
    const event_id = event.target.id.replace(/\D/g, '');
    const marker = this.mapMarkers.find(marker => marker.id == event_id);
    // Opens popup
    const turboFrame = document.getElementById('map-left-popup');
    turboFrame.setAttribute("src", this.popupUrlValue + event_id);
    // Opens marker
    marker.setIcon(this.clickedimageurlValue);
    google.maps.event.trigger(marker, "mouseover");

    sessionStorage.setItem('selected_marker', marker.id);
    this.resetMarkers(event_id);
  }

  hidePopup() {
    this.popupTarget.classList.add('hidden');
  }

  resetMarkers(event_id = null) {
    this.mapMarkers.forEach(marker => {
      if (marker.id !== event_id) {
        marker.setIcon(this.image);
        marker.setAnimation(null);
      }
    });
  }

  cleanLocalStorage() {
    sessionStorage.removeItem('selected_marker');
    sessionStorage.removeItem('marker_infowindow');
  }

  // Left map popup functions end here

  scrollToSelectedLocation(){
    if(sessionStorage.getItem('marker_infowindow')) {
      let id = sessionStorage.getItem('marker_infowindow').split('_')[1]
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

    const clickedLocation = this.hasPopupTarget;
    let selectedMarker = sessionStorage.getItem('selected_marker');
    if (clickedLocation) this.popupTarget.classList.remove('hidden');
    if (selectedMarker) {
      let marker = this.mapMarkers.find((marker) => { return marker.id == selectedMarker });
      marker.setIcon(clickedImage);
    }
  }

  setMarkers(map, image, clickedImage) {
    // Adds markers to the map.
    let prevInfoWindow = false
    let pin = document.getElementById(sessionStorage.getItem('marker_infowindow'))

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
        this.mapMarkers.forEach((marker) => {
          marker.setIcon(image)
          marker.setAnimation(null);
        })

        // Opens popup(url is provided only on desktop)
        if (this.hasPopupUrlValue) {
          const turboFrame = document.getElementById('map-left-popup');
          turboFrame.setAttribute("src", this.popupUrlValue + element_id);
        }
        marker.setIcon(clickedImage);
        sessionStorage.setItem('selected_marker', marker.id);

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
        sessionStorage.setItem('marker_infowindow', element.id)
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

        sessionStorage.setItem('marker_infowindow', element.id)
        // Scroll method calling was here, removed so that it doesn't scroll on mouseover.
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
