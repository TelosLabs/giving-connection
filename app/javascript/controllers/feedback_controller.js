import { Controller } from "@hotwired/stimulus"

// Controls the floating feedback widget: toggling between the closed
// trigger (button + tooltip) and the open form panel, selecting a rating
// face, enabling the submit button, and showing a success tooltip after
// a successful submit.
export default class extends Controller {
  static targets = [
    "trigger", "panel", "tooltip", "face", "ratingInput", "submit",
    "dropdown", "dropdownMenu", "dropdownLabel", "categoryInput"
  ]

  // Classes applied to the selected rating face.
  static selectedClasses = ["bg-gray-8", "ring-1", "ring-blue-medium"]

  open(event) {
    event?.preventDefault()
    this.triggerTarget.classList.add("hidden")
    this.panelTarget.classList.remove("hidden")
  }

  close(event) {
    event?.preventDefault()
    this.panelTarget.classList.add("hidden")
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
      face.classList.toggle("bg-gray-8", selected)
      face.classList.toggle("ring-1", selected)
      face.classList.toggle("ring-blue-medium", selected)
      face.setAttribute("aria-pressed", selected)
    })

    this.enableSubmit()
  }

  // ---------- Category dropdown ----------

  toggleDropdown(event) {
    event?.preventDefault()
    this.dropdownMenuTarget.classList.toggle("hidden")
  }

  selectCategory(event) {
    const option = event.currentTarget
    this.categoryInputTarget.value = option.dataset.value

    // Mirror the option's icon + text into the trigger label.
    this.dropdownLabelTarget.innerHTML = option.innerHTML
    this.dropdownLabelTarget.classList.remove("text-gray-4")
    this.dropdownLabelTarget.classList.add("text-gray-2")

    this.closeDropdown()
  }

  closeDropdown() {
    this.dropdownMenuTarget.classList.add("hidden")
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

  // On a successful submit the server returns a Turbo Stream that shows the
  // green success notification at the top of the page; here we just tidy up
  // the widget by clearing the form and collapsing the panel.
  afterSubmit(event) {
    if (!event.detail.success) return

    this.reset()
    this.close()
  }

  reset() {
    this.element.querySelector("form")?.reset()
    this.ratingInputTarget.value = ""

    this.faceTargets.forEach((face) => {
      face.classList.remove("bg-gray-8", "ring-1", "ring-blue-medium")
      face.setAttribute("aria-pressed", "false")
    })

    // Reset the category dropdown back to its placeholder.
    this.categoryInputTarget.value = ""
    this.dropdownLabelTarget.textContent = "Select an option..."
    this.dropdownLabelTarget.classList.add("text-gray-4")
    this.dropdownLabelTarget.classList.remove("text-gray-2")
    this.closeDropdown()

    this.submitTarget.disabled = true
    this.submitTarget.classList.add("bg-gray-4", "opacity-60", "cursor-not-allowed")
    this.submitTarget.classList.remove("bg-blue-dark")
  }
}
