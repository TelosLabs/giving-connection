import { Controller } from "@hotwired/stimulus"

// Opens the Smart Match results' service filter in a modal dialog.
//
// A native <dialog> rather than the app's `modal` controller: that one carries
// the search page's filter machinery (unsaved-change prompts, applied badges,
// checkbox restore) and expects that page's markup. Here the browser already
// gives us the backdrop, Escape-to-close, focus trapping and the top layer for
// free, so the controller is only the open/close verbs.
//
// Closing is deliberately NOT the same as applying: only the form's submit
// button changes what is on screen, so a user who opened this out of curiosity
// can always back out. Dismissing therefore rewinds the boxes to the state the
// server rendered (form.reset() restores the `checked` attributes), or reopening
// would show ticks that are not reflected in the results behind it.
//
// Applying needs no close handler. The dialog lives inside the results Turbo
// frame, so submitting replaces it with a freshly-closed copy carrying the new
// state.
export default class extends Controller {
  static targets = ["dialog", "form"]

  open(event) {
    event.preventDefault()
    this.dialogTarget.showModal()
  }

  close(event) {
    if (event) event.preventDefault()
    this.dialogTarget.close()
  }

  // Fires for every dismissal -- the close button, Escape, the backdrop.
  rewind() {
    if (this.hasFormTarget) this.formTarget.reset()
  }

  // A click on the backdrop lands on the dialog element itself rather than on
  // any of its children.
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
