import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "pin" ]


    reloadPage(event) {
        window.location.search = window.location.search
    }
}
