import { Controller } from "@hotwired/stimulus"

// Flags that there is more content below the fold, so the fade over the wizard
// footer (see _smart_match.scss) can appear only when it is telling the truth.
//
// Quiz steps with many options run past the viewport, and the sticky footer
// reads as the end of the page -- users were not realising there were more
// options below. A fade that is always on would be a worse lie in the other
// direction, claiming more content on the last screen of every step, so this
// sets data-more-below="true" only while something is actually left to scroll
// and clears it once the last option is in view.
//
// Two scroll layouts have to work. The wizard's content pane is a flex child
// with overflow-y-auto, which becomes the scroller when the flex line pins it to
// the viewport height; when it does not, the pane grows and the document scrolls
// instead. Rather than depend on which one wins, ask the pane whether it has any
// overflow and fall back to the document.
export default class extends Controller {
  static targets = ["pane"]
  static values = { threshold: { type: Number, default: 24 } }

  connect() {
    this.scheduleUpdate = this.scheduleUpdate.bind(this)

    // Step content is swapped into a Turbo frame, and options can expand an
    // accordion, so height changes without any scrolling.
    this.resizeObserver = new ResizeObserver(this.scheduleUpdate)
    this.resizeObserver.observe(this.element)

    window.addEventListener("scroll", this.scheduleUpdate, { passive: true })
    window.addEventListener("resize", this.scheduleUpdate, { passive: true })
    // Scroll events from an inner scroller do not reach window.
    if (this.hasPaneTarget) {
      this.paneTarget.addEventListener("scroll", this.scheduleUpdate, { passive: true })
    }

    this.update()
  }

  disconnect() {
    this.resizeObserver.disconnect()
    window.removeEventListener("scroll", this.scheduleUpdate)
    window.removeEventListener("resize", this.scheduleUpdate)
    if (this.hasPaneTarget) {
      this.paneTarget.removeEventListener("scroll", this.scheduleUpdate)
    }
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  scheduleUpdate() {
    if (this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.update()
    })
  }

  // Tapping the chevron advances most of a screen rather than a full one, so the
  // options that were at the bottom edge stay visible as context.
  scrollDown() {
    const scroller = this.scroller

    scroller.scrollBy({ top: scroller.clientHeight * 0.8, behavior: "smooth" })
  }

  update() {
    const scroller = this.scroller
    const remaining = scroller.scrollHeight - scroller.clientHeight - scroller.scrollTop

    this.element.dataset.moreBelow = remaining > this.thresholdValue ? "true" : "false"
  }

  get scroller() {
    if (this.hasPaneTarget && this.paneTarget.scrollHeight - this.paneTarget.clientHeight > 1) {
      return this.paneTarget
    }

    return document.scrollingElement || document.documentElement
  }
}
