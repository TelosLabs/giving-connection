import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "pin" ]

    connect(){

    }

    reloadPage(event) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);

        if( !urlParams.has('location_id') ) {
            urlParams.append('location_id', this.pinTarget.id)
        }else{
            urlParams.set('location_id', this.pinTarget.id)
        }
        window.location.search = urlParams.toString()
    }
}
