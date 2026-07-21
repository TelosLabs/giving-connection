import { Controller } from "@hotwired/stimulus"

// Polls the Smart Match status endpoint while matches are computed off the
// request thread by ProcessSubmissionJob. When the job finishes ("ready") or
// fails ("unavailable"), it navigates to the results page to render the final
// state. Stops cleanly on disconnect so a Turbo visit can't leave a poll running.
export default class extends Controller {
  static values = {
    statusUrl: String,
    redirectUrl: String,
    interval: { type: Number, default: 2000 }
  }

  connect() {
    this.stopped = false
    this.schedulePoll()
  }

  disconnect() {
    this.stopped = true
    if (this.timeout) clearTimeout(this.timeout)
    if (this.abortController) this.abortController.abort()
  }

  schedulePoll() {
    if (this.stopped) return
    this.timeout = setTimeout(() => this.poll(), this.intervalValue)
  }

  async poll() {
    if (this.stopped) return

    try {
      this.abortController = new AbortController()
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) {
        this.schedulePoll()
        return
      }

      const { status } = await response.json()
      if (status === "processing") {
        this.schedulePoll()
      } else {
        this.reload()
      }
    } catch (error) {
      // Network blip or aborted fetch — keep polling unless we're tearing down.
      if (!this.stopped) this.schedulePoll()
    }
  }

  reload() {
    if (window.Turbo) {
      window.Turbo.visit(this.redirectUrlValue, { action: "replace" })
    } else {
      window.location.assign(this.redirectUrlValue)
    }
  }
}
