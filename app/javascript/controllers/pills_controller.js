import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = [ "pills" ]
  static values = { index: Number }

  initialize() {
    console.log(this.indexValue);
    console.log(typeof this.indexValue);
  }

  displayPills() {
    console.log("displayPills");
    this.pillsTarget.classList.toggle("hidden");
  }
}
