import { Controller } from "@hotwired/stimulus"

// Keeps keyboard focus attached to the results after "Show more".
//
// "Show more" targets the smart-match-results frame, so Turbo replaces the
// frame's contents -- including the button that was just activated. Focus has
// nowhere to return to and falls back to <body>, which drops a keyboard user at
// the top of the document and leaves a screen reader with no idea the page grew.
// The count line's aria-live does not rescue it either: that element is itself
// replaced, and a live region inserted alongside its own content is not reliably
// announced.
//
// So after each frame load we move focus to the count line ("Showing 12 of 40"),
// which reads the new total aloud and sits directly above the next "Show more".
//
// The controller lives on the frame element, which Turbo keeps across renders,
// so `armed` survives the swap that removes the button. It is set only by an
// actual click: turbo:frame-load also fires for loads the user did not ask for,
// and stealing focus on those would be worse than leaving it alone.
export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.armed = false
  }

  arm() {
    this.armed = true
  }

  focusStatus() {
    if (!this.armed) return
    this.armed = false

    if (!this.hasStatusTarget) return
    this.statusTarget.focus()
  }
}
