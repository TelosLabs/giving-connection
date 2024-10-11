import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ["dots", "readMoreButton", "collapsableText", "anchor"]
  }

  toggleVisibility() {
    this.collapsableTextTarget.classList.toggle("hidden")
    this.dotsTarget.classList.toggle("hidden")
    this.readMoreButtonTarget.innerHTML = this.readMoreButtonTarget.innerHTML === "Read More" ? "Read Less" : "Read More"
  }
}