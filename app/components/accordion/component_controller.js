import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['arrow']
  }

  rotateArrow() {
    this.arrowTarget.classList.toggle('rotate-svg')
  }
}
