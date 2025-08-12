import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { profileUrl: String }

    redirectToProfile(event) {
        event.preventDefault()

        if (this.hasProfileUrlValue) {
            window.location.href = this.profileUrlValue
        } else {
            console.error("Organization profile URL not provided.")
        }
    }
}