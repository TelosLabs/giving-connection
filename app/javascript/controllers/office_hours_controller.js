import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "closedCheckbox", "openTime", "closeTime" ]

  connect() {
    this.toggleTimeFields()
  }

  toggleTimeFields() {
    if (!this.hasClosedCheckboxTarget || !this.hasOpenTimeTarget || !this.hasCloseTimeTarget) {
      return
    }

    const isClosed = this.closedCheckboxTarget.checked

    if (isClosed) {
      this.openTimeTarget.disabled = true
      this.closeTimeTarget.disabled = true
      this.openTimeTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.closeTimeTarget.classList.add('opacity-50', 'cursor-not-allowed')
    } else {
      this.openTimeTarget.disabled = false
      this.closeTimeTarget.disabled = false
      this.openTimeTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.closeTimeTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }
}