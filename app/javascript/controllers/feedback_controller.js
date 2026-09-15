import { Controller } from "@hotwired/stimulus"

// Controls the floating feedback widget: toggling between the closed
// trigger (button + tooltip) and the open form panel, selecting a rating
// face and a category, and enabling the submit button. The success
// notification itself is rendered by the server as a Turbo Stream.
export default class extends Controller {
  static targets = [
    "trigger", "panel", "backdrop", "tooltip", "face", "ratingInput", "submit",
    "dropdown", "dropdownButton", "dropdownMenu", "dropdownLabel", "option",
    "categoryInput", "error"
  ]

  // exitIntent enables the "about to leave the page" behavior (nonprofit pages).
  static values = { exitIntent: Boolean }

  // Classes applied to the selected rating face.
  static selectedClasses = ["bg-gray-8", "ring-1", "ring-blue-medium"]

  // Classes that turn the corner panel into a centered modal (exit case only).
  static MODAL_CLASSES = [
    "fixed", "top-1/2", "left-1/2", "-translate-x-1/2", "-translate-y-1/2",
    "z-50", "max-h-[90vh]", "overflow-y-auto"
  ]

  static STORAGE_KEY = "gc:feedbackSubmitted"

  // accessiBe (loaded in the application layout) drops a floating trigger in the
  // bottom-right corner, the same corner as this widget. It is licensed per
  // domain, so it renders on production but not on localhost or staging. Rather
  // than hardcode "shift on production", we look for the trigger itself and only
  // step aside when it is really there.
  static A11Y_TRIGGER_SELECTOR = ".acsb-trigger:not(.acsb-hidden):not(.acsb-trigger-hidden)"
  static A11Y_DEFAULT_CLASSES = ["bottom-6"]
  static A11Y_SHIFTED_CLASSES = ["bottom-24", "sm:bottom-6", "sm:right-24"]
  static A11Y_WATCH_MS = 15000

  connect() {
    this.watchAccessibilityTrigger()

    if (!this.exitIntentValue || this.hasSentFeedback()) return

    this.exitIntentShown = false

    // Desktop only: detect the cursor leaving the viewport toward the top
    // (heading for the tab bar, address bar, or close button). We intentionally
    // do NOT hijack the browser Back button: pushState/popstate fights Turbo
    // Drive's own history handling and traps users on the page.
    if (window.matchMedia("(hover: hover)").matches) {
      this.onMouseOut = this.onMouseOut.bind(this)
      document.addEventListener("mouseout", this.onMouseOut)
    }
  }

  disconnect() {
    if (this.onMouseOut) document.removeEventListener("mouseout", this.onMouseOut)
    this.stopWatchingAccessibilityTrigger()
  }

  // ---------- Accessibility widget avoidance ----------

  watchAccessibilityTrigger() {
    if (this.positionAroundAccessibilityTrigger()) return

    // accessiBe is injected by an async script that validates the licence before
    // rendering anything, so the trigger can show up well after we connect.
    this.a11yObserver = new MutationObserver(() => {
      if (this.positionAroundAccessibilityTrigger()) this.stopWatchingAccessibilityTrigger()
    })
    this.a11yObserver.observe(document.body, { childList: true, subtree: true })

    // On environments without the widget the trigger never arrives; stop
    // watching rather than keep an observer on the whole body for the page's life.
    this.a11yTimeout = setTimeout(
      () => this.stopWatchingAccessibilityTrigger(),
      this.constructor.A11Y_WATCH_MS
    )
  }

  // Moves the widget clear of the accessibility trigger. Returns true once the
  // trigger has been found, which is the signal to stop watching for it.
  positionAroundAccessibilityTrigger() {
    if (!document.querySelector(this.constructor.A11Y_TRIGGER_SELECTOR)) return false

    this.element.classList.remove(...this.constructor.A11Y_DEFAULT_CLASSES)
    this.element.classList.add(...this.constructor.A11Y_SHIFTED_CLASSES)
    return true
  }

  stopWatchingAccessibilityTrigger() {
    this.a11yObserver?.disconnect()
    this.a11yObserver = null
    clearTimeout(this.a11yTimeout)
  }

  // ---------- Exit intent ----------

  onMouseOut(event) {
    // Cursor left through the top edge of the window (heading for the tab bar,
    // address bar, or close button).
    if (event.clientY > 0 || event.relatedTarget) return
    this.triggerExitIntent()
  }

  triggerExitIntent() {
    if (this.exitIntentShown || this.hasSentFeedback()) return
    if (!this.hasPanelTarget || !this.panelTarget.classList.contains("hidden")) return // already open

    this.exitIntentShown = true
    this.openAsModal()
  }

  // Open the form as a centered modal with a dark overlay (exit case only).
  openAsModal() {
    this.triggerTarget.classList.add("hidden")
    this.panelTarget.classList.remove("hidden")
    this.panelTarget.classList.add(...this.constructor.MODAL_CLASSES)
    if (this.hasBackdropTarget) this.backdropTarget.classList.remove("hidden")
  }

  hasSentFeedback() {
    try {
      return window.localStorage.getItem(this.constructor.STORAGE_KEY) === "true"
    } catch {
      return false
    }
  }

  markFeedbackSent() {
    try {
      window.localStorage.setItem(this.constructor.STORAGE_KEY, "true")
    } catch {
      // Storage unavailable (private mode / disabled), ignore.
    }
  }

  // locations/show keeps Turbo's default page caching, so an open panel (or the
  // exit-intent modal and its backdrop) would be captured in the snapshot and
  // painted already-open when the visitor hits Back. Collapse it first.
  beforeCache() {
    this.close()
  }

  open(event) {
    event?.preventDefault()
    this.triggerTarget.classList.add("hidden")
    this.panelTarget.classList.remove("hidden")
  }

  close(event) {
    event?.preventDefault()
    this.panelTarget.classList.add("hidden")
    // Undo any centered-modal styling so the next open shows the corner panel.
    this.panelTarget.classList.remove(...this.constructor.MODAL_CLASSES)
    if (this.hasBackdropTarget) this.backdropTarget.classList.add("hidden")
    this.triggerTarget.classList.remove("hidden")
  }

  // Dismiss just the "Have any feedback?" tooltip, leaving the button.
  dismissTooltip(event) {
    event?.preventDefault()
    this.tooltipTarget.classList.add("hidden")
  }

  selectRating(event) {
    const button = event.currentTarget
    this.ratingInputTarget.value = button.dataset.rating

    this.faceTargets.forEach((face) => {
      const selected = face === button
      this.constructor.selectedClasses.forEach((cls) => face.classList.toggle(cls, selected))
      face.setAttribute("aria-pressed", selected)
    })

    this.enableSubmit()
  }

  // ---------- Category dropdown ----------

  get dropdownOpen() {
    return !this.dropdownMenuTarget.classList.contains("hidden")
  }

  toggleDropdown(event) {
    event?.preventDefault()
    this.dropdownOpen ? this.closeDropdown() : this.openDropdown()
  }

  openDropdown() {
    this.dropdownMenuTarget.classList.remove("hidden")
    this.dropdownButtonTarget.setAttribute("aria-expanded", "true")
  }

  closeDropdown() {
    this.dropdownMenuTarget.classList.add("hidden")
    this.dropdownButtonTarget.setAttribute("aria-expanded", "false")
  }

  selectCategory(event) {
    const option = event.currentTarget
    this.categoryInputTarget.value = option.dataset.value

    // Show the option's own icon + text in the trigger label. The nodes are
    // cloned rather than rebuilt from an HTML string, so the label markup stays
    // defined in one place: the server-rendered option.
    this.dropdownLabelTarget.replaceChildren(
      ...Array.from(option.childNodes, (node) => node.cloneNode(true))
    )
    this.dropdownLabelTarget.classList.remove("text-gray-4")
    this.dropdownLabelTarget.classList.add("text-gray-2")

    this.optionTargets.forEach((el) => el.setAttribute("aria-selected", el === option))

    this.closeDropdown()
    this.dropdownButtonTarget.focus()
  }

  // Escape closes the listbox, the arrow keys walk it. Enter/Space already
  // activate an option because each one is a real <button>.
  dropdownKeydown(event) {
    switch (event.key) {
      case "Escape":
        if (!this.dropdownOpen) return
        event.stopPropagation()
        this.closeDropdown()
        this.dropdownButtonTarget.focus()
        break
      case "ArrowDown":
        event.preventDefault()
        this.moveOptionFocus(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveOptionFocus(-1)
        break
    }
  }

  moveOptionFocus(step) {
    if (!this.dropdownOpen) this.openDropdown()

    const options = this.optionTargets
    if (options.length === 0) return

    const current = options.indexOf(document.activeElement)
    // From the trigger (current === -1) ArrowDown lands on the first option and
    // ArrowUp on the last; otherwise clamp inside the list.
    const next = current === -1
      ? (step > 0 ? 0 : options.length - 1)
      : Math.min(Math.max(current + step, 0), options.length - 1)

    options[next].focus()
  }

  closeDropdownOutside(event) {
    if (this.hasDropdownTarget && !this.dropdownTarget.contains(event.target)) {
      this.closeDropdown()
    }
  }

  enableSubmit() {
    this.submitTarget.disabled = false
    this.submitTarget.classList.remove("bg-gray-4", "opacity-60", "cursor-not-allowed")
    this.submitTarget.classList.add("bg-blue-dark")
  }

  // Turbo Drive disables the submitter for the duration of the request, but only
  // after its own submit-start handling; locking it here closes the window where
  // a second click sends a second POST.
  disableSubmit() {
    this.submitTarget.disabled = true
    this.hideError()
  }

  // On a successful submit the server returns a Turbo Stream that shows the
  // green success notification at the top of the page; here we just tidy up
  // the widget by clearing the form and collapsing the panel. On failure
  // (Rack::Attack 429, 5xx) there is no stream to render, so the widget has to
  // say something itself or the panel just sits there looking frozen.
  afterSubmit(event) {
    if (!event.detail.success) {
      this.showError()
      this.enableSubmit()
      return
    }

    // Remember that feedback was sent so exit-intent no longer fires.
    this.markFeedbackSent()
    this.reset()
    this.close()
  }

  showError() {
    if (this.hasErrorTarget) this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    if (this.hasErrorTarget) this.errorTarget.classList.add("hidden")
  }

  reset() {
    this.element.querySelector("form")?.reset()
    this.ratingInputTarget.value = ""

    this.faceTargets.forEach((face) => {
      face.classList.remove(...this.constructor.selectedClasses)
      face.setAttribute("aria-pressed", "false")
    })

    // Reset the category dropdown back to its placeholder.
    this.categoryInputTarget.value = ""
    this.dropdownLabelTarget.textContent = "Select an option..."
    this.dropdownLabelTarget.classList.add("text-gray-4")
    this.dropdownLabelTarget.classList.remove("text-gray-2")
    this.optionTargets.forEach((el) => el.setAttribute("aria-selected", "false"))
    this.closeDropdown()
    this.hideError()

    this.submitTarget.disabled = true
    this.submitTarget.classList.add("bg-gray-4", "opacity-60", "cursor-not-allowed")
    this.submitTarget.classList.remove("bg-blue-dark")
  }
}
