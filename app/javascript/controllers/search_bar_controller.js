import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["location", "lat", "lon"]
    static values = {
        latitude: Number,
        longitude: Number
    }

    connect() {
        console.log("connected")
    }

    async change(event) {
        console.log(event)
        switch(event.target.value) {
            case "Current Location, ":
                await this.askForGeoPermissions(event)
            default:
                this.latTarget.value = event.target.options[event.target.selectedIndex].getAttribute("latitude")
                this.lonTarget.value = event.target.options[event.target.selectedIndex].getAttribute("longitude")
        }
    }

    async askForGeoPermissions(event){
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                event.target.options[event.target.selectedIndex].setAttribute("latitude", position.coords.latitude)
                event.target.options[event.target.selectedIndex].setAttribute("longitude", position.coords.longitude)
            })
        } else {
            console.log('Geolocation is not supported by your browser');
        }
    }
}