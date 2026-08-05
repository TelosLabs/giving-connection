import { Controller } from "@hotwired/stimulus"

// Polls the Smart Match status endpoint while matches are computed off the
// request thread by ProcessSubmissionJob. When the job finishes ("ready") or
// fails ("unavailable"), it navigates to the results page to render the final
// state. Stops cleanly on disconnect so a Turbo visit can't leave a poll running.
//
// Two terminal states are handled here rather than server-side, because the
// reason we stopped getting answers may be that the server is refusing to
// answer at all (rate limit, restart, dropped connection):
//
//   delayed — polls keep succeeding but the job is still running past
//             DEADLINE. Nothing is broken; the work is just slow.
//   failed  — MAX_FAILURES consecutive polls could not be read (any HTTP
//             error, including 429, or a network error). We cannot tell how
//             long that will last, so we stop and hand it back to the user.
//
// Both swap in markup already present in the page, so they render even when
// every request to the server is failing. Previously any non-OK response was
// treated as "still processing", which turned a rate limit into a spinner that
// never resolved and gave the user no indication anything was wrong.
export default class extends Controller {
  static targets = ["spinner", "delayed", "failed"]

  static values = {
    statusUrl: String,
    redirectUrl: String,
    interval: { type: Number, default: 2000 },
    // Consecutive unreadable responses before giving up.
    maxFailures: { type: Number, default: 5 },
    // Ceiling on the retry backoff, so giving up stays ~40s away rather than
    // doubling into minutes.
    maxBackoff: { type: Number, default: 15000 },
    // How long to keep waiting on a job that is still legitimately running.
    deadline: { type: Number, default: 120000 }
  }

  connect() {
    this.stopped = false
    this.failures = 0
    this.startedAt = Date.now()
    this.schedulePoll()
  }

  disconnect() {
    this.stopped = true
    if (this.timeout) clearTimeout(this.timeout)
    if (this.abortController) this.abortController.abort()
  }

  schedulePoll(delay = this.intervalValue) {
    if (this.stopped) return
    this.timeout = setTimeout(() => this.poll(), delay)
  }

  async poll() {
    if (this.stopped) return

    let status
    try {
      this.abortController = new AbortController()
      const response = await fetch(this.statusUrlValue, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) return this.recordFailure()

      status = (await response.json()).status
    } catch (error) {
      // Aborted by disconnect() — not a real failure, and the controller is
      // already tearing down.
      if (this.stopped) return
      return this.recordFailure()
    }

    this.failures = 0

    if (status !== "processing") return this.reload()
    if (Date.now() - this.startedAt >= this.deadlineValue) return this.stopWith("delayed")

    this.schedulePoll()
  }

  recordFailure() {
    this.failures += 1
    if (this.failures >= this.maxFailuresValue) return this.stopWith("failed")

    // Back off exponentially. Beyond being polite to a struggling server, this
    // matters for the rate-limit case specifically: polling at a fixed interval
    // holds the limit window open indefinitely, so a throttled page could never
    // recover on its own.
    this.schedulePoll(Math.min(this.intervalValue * 2 ** this.failures, this.maxBackoffValue))
  }

  // Swap the spinner for a terminal message. Guarded on target presence so the
  // controller still degrades to "keep spinning" if the markup is ever absent.
  stopWith(state) {
    this.stopped = true
    if (this.timeout) clearTimeout(this.timeout)

    const delayed = state === "delayed"
    if (delayed ? !this.hasDelayedTarget : !this.hasFailedTarget) return

    if (this.hasSpinnerTarget) this.spinnerTarget.hidden = true
    ;(delayed ? this.delayedTarget : this.failedTarget).hidden = false
  }

  reload() {
    if (window.Turbo) {
      window.Turbo.visit(this.redirectUrlValue, { action: "replace" })
    } else {
      window.location.assign(this.redirectUrlValue)
    }
  }
}
