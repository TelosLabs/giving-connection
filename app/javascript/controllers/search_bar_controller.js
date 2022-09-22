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
}