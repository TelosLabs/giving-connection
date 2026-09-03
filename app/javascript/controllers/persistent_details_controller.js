import { Controller } from "@hotwired/stimulus"

// Keeps a <details> element open across re-renders.
//
// The Smart Match criteria panel sits inside the same Turbo frame as the result
// cards, because it reports how many of the SHOWN matches meet each criterion.
// Every "Show more" therefore replaces it, which would otherwise slam the panel
// shut on a user who had deliberately opened it and is now paging through
// results.
//
// sessionStorage rather than a URL param: the state is a UI preference, not
// something worth putting in a shareable link, and it survives a full reload of
// the results page too.
export default class extends Controller {
  static values = { key: String }

  connect() {
    if (this.read() === "open") this.element.open = true
  }

  save() {
    this.write(this.element.open ? "open" : "closed")
  }

  read() {
    try {
      return sessionStorage.getItem(this.storageKey)
    } catch {
      // Private browsing modes can refuse storage entirely; the panel just
      // falls back to its default state.
      return null
    }
  }

  write(state) {
    try {
      sessionStorage.setItem(this.storageKey, state)
    } catch {
      // See read().
    }
  }

  get storageKey() {
    return `details:${this.keyValue || this.element.id || "default"}`
  }
}
