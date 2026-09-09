import { Controller } from "@hotwired/stimulus"

// Expands the collapsed "Why this match" chips on a Smart Match result card.
//
// The card leads with only the strongest few reasons so a user who answered a
// lot of questions does not get a wall of chips, but the remainder are rendered
// in place and merely hidden -- expanding is a class toggle, not a fetch, so
// each card expands independently and nothing has to round-trip to the server.
export default class extends Controller {
  static targets = ["extraReason", "toggle", "moreLabel", "lessLabel"]

  toggle() {
    const expanded = this.toggleTarget.getAttribute("aria-expanded") === "true"

    this.toggleTarget.setAttribute("aria-expanded", String(!expanded))
    this.extraReasonTargets.forEach((chip) => chip.classList.toggle("hidden", expanded))
    this.moreLabelTarget.classList.toggle("hidden", !expanded)
    this.lessLabelTarget.classList.toggle("hidden", expanded)
  }
}
