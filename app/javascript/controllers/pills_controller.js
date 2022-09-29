import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['pills', "pills_counter"]
  }

  connect() {
    let checks = this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').length
    let radio = this.pillsTarget.querySelectorAll('input[type="radio"]:checked').length
    this.pills_counterTarget.innerHTML = checks + radio
  }
}
