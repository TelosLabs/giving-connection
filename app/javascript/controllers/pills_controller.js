import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = [ "pills" ]

  displayPills() {
    console.log("displayPills");
    this.pillsTarget.classList.toggle("hidden");
  }
}
