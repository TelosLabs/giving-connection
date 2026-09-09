import { Controller } from "@hotwired/stimulus"

// Owns the quiz wizard's scroll geometry: makes the step pane the one and only
// scroller, and flags when there is genuinely more of a step below the fold.
//
// Why the available height has to be measured. The navbar sits in normal flow
// above the wizard, so `min-height: 100vh` made the section overshoot the space
// left for it by the navbar's height. Two bugs came out of that:
//
//   * the pane inherited a height its content did not need, so a step whose
//     answers ended 300px early still scrolled 300px into blank white;
//   * whether the pane or the document scrolled flipped with content length --
//     on the causes step BOTH did, so scrolling the document to its end left the
//     pane mid-scroll, and the fade stayed on top of the answers with no way to
//     clear it.
//
// Setting the real available height fixes the pane as the scroller, which makes
// the cue's measurement meaningful and removes the empty tail. The navbar's
// height is responsive (its links wrap at some widths), so it is measured rather
// than hardcoded.
export default class extends Controller {
  static targets = ["pane", "content"]
  static values = { threshold: { type: Number, default: 24 } }

  connect() {
    this.refresh = this.refresh.bind(this)
    this.scheduleUpdate = this.scheduleUpdate.bind(this)

    // The step's content grows and shrinks without any scrolling: Turbo swaps a
    // new step into the frame, and the causes accordion expands in place. The
    // pane's own box never changes now that its height is fixed, so watch the
    // content instead.
    this.resizeObserver = new ResizeObserver(this.scheduleUpdate)
    this.resizeObserver.observe(this.hasContentTarget ? this.contentTarget : this.element)

    window.addEventListener("resize", this.refresh, { passive: true })
    window.addEventListener("scroll", this.scheduleUpdate, { passive: true })
    // Scroll events from an inner scroller do not reach window.
    if (this.hasPaneTarget) {
      this.paneTarget.addEventListener("scroll", this.scheduleUpdate, { passive: true })
    }

    this.refresh()
  }

  disconnect() {
    this.resizeObserver.disconnect()
    window.removeEventListener("resize", this.refresh)
    window.removeEventListener("scroll", this.scheduleUpdate)
    if (this.hasPaneTarget) {
      this.paneTarget.removeEventListener("scroll", this.scheduleUpdate)
    }
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  refresh() {
    this.setAvailableHeight()
    this.update()
  }

  // Tapping the chevron advances most of a screen rather than a full one, so the
  // options that were at the bottom edge stay visible as context.
  scrollDown() {
    const scroller = this.scroller

    scroller.scrollBy({ top: scroller.clientHeight * 0.8, behavior: "smooth" })
  }

  scheduleUpdate() {
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.update()
    })
  }

  // Everything in flow above the wizard -- the navbar, plus flash messages when
  // there are any. Read from the document rather than from a constant so a
  // taller navbar (narrow widths wrap its links) cannot reintroduce the tail.
  setAvailableHeight() {
    const offset = Math.max(0, Math.round(this.element.getBoundingClientRect().top + window.scrollY))

    this.element.style.setProperty("--sm-wizard-offset", `${offset}px`)
  }

  update() {
    const scroller = this.scroller
    const remaining =
      scroller.scrollHeight - scroller.clientHeight - scroller.scrollTop - this.bottomClearance(scroller)

    this.element.dataset.moreBelow = remaining > this.thresholdValue ? "true" : "false"
  }

  // The pane carries bottom padding so the last answers can scroll clear of the
  // fade instead of ending underneath it. That padding is scrollable distance
  // with nothing in it, so it must not read as "more below" -- otherwise the cue
  // points at its own clearance.
  bottomClearance(scroller) {
    return parseFloat(getComputedStyle(scroller).paddingBottom) || 0
  }

  // The pane, unconditionally: with the height fixed it is the only scroller for
  // step content. The document scrolls too -- the site footer sits below the
  // wizard -- but that is site chrome, not answers, and a cue pointing at it
  // would send users away from the question.
  get scroller() {
    return this.hasPaneTarget ? this.paneTarget : document.scrollingElement || document.documentElement
  }
}
