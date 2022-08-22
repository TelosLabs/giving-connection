import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "pin" ]

    connect(){

    }

    reloadPage(event) {
        window.location.reload()
    }
}
