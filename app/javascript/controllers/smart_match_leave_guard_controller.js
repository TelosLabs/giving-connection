import { Controller } from "@hotwired/stimulus"

// Guards the Smart Match results page against accidental navigation away --
// chiefly the browser BACK button, which would drop the user on a stale quiz
// step (the wizard is server-side session state) and re-submit on the way
// forward. Browsers do not allow a site to truly disable the back button, so
// the best we can do is intercept the unload and prompt with the native
// "Leave site?" dialog.
//
// This only works if the results page was entered as a real navigation rather
// than a Turbo Drive visit -- otherwise back is an in-app snapshot restore and
// never triggers `beforeunload`. The final quiz form opts out of Turbo
// (`data: { turbo: false }`) precisely so this guard has a real unload to catch.
//
// In-page controls (retake, still-need-help, match cards) are Turbo visits and
// do NOT unload the document, so they never trigger the prompt. External links,
// refresh, tab close, and the back button do.
export default class extends Controller {
  connect () {
    this.armed = true
    this.beforeUnloadHandler = this.confirmLeave.bind(this)
    window.addEventListener("beforeunload", this.beforeUnloadHandler)
  }

  disconnect () {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  }

  confirmLeave (event) {
    if (!this.armed) return

    // Modern browsers ignore custom text and show their own generic message,
    // but setting returnValue is still required to trigger the prompt at all.
    event.preventDefault()
    event.returnValue = ""
    return ""
  }

  // Wire this to any control that should navigate away without prompting.
  allow () {
    this.armed = false
  }
}
