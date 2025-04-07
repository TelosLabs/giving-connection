import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ["dots", "readMoreButton", "collapsableText", "anchor"]
  }

  connect() {
    window.addEventListener("bio-card:toggle", this.handleToggleEvent.bind(this))
  }

  disconnect() {
    window.removeEventListener("bio-card:toggle", this.handleToggleEvent.bind(this))
  }

  toggleVisibility() {
    window.dispatchEvent(new CustomEvent("bio-card:toggle", { detail: { source: this.element } }))

    const isHidden = this.collapsableTextTarget.classList.contains("hidden")
    this.collapsableTextTarget.classList.toggle("hidden", !isHidden)
    this.dotsTarget.classList.toggle("hidden", isHidden)
    this.readMoreButtonTarget.innerHTML = isHidden ? "Read Less" : "Read More"

    const yOffset = -100
    const yPosition = this.anchorTarget.getBoundingClientRect().top + window.scrollY + yOffset
    window.scrollTo({ top: yPosition, behavior: "smooth" })

  }

  handleToggleEvent(event) {
    if (event.detail.source === this.element) return

    if (!this.collapsableTextTarget.classList.contains("hidden")) {
      this.collapsableTextTarget.classList.add("hidden")
      this.dotsTarget.classList.remove("hidden")
      this.readMoreButtonTarget.innerHTML = "Read More"
    }
  }
}
