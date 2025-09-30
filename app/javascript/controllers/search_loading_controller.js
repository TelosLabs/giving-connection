import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['spinner']

  connect () {
    // Store bound functions for proper cleanup
    this.boundShowSpinner = this.showSpinner.bind(this)
    this.boundHideSpinner = this.hideSpinner.bind(this)
    this.boundHandlePaginationClick = this.handlePaginationClick.bind(this)

    // Listen for Turbo Frame events
    this.element.addEventListener('turbo:before-frame-request', this.boundShowSpinner)
    this.element.addEventListener('turbo:frame-load', this.boundHideSpinner)
    this.element.addEventListener('turbo:before-frame-render', this.boundHideSpinner)

    // Listen for clicks on pagination links
    this.element.addEventListener('click', this.boundHandlePaginationClick)
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-frame-request', this.boundShowSpinner)
    this.element.removeEventListener('turbo:frame-load', this.boundHideSpinner)
    this.element.removeEventListener('turbo:before-frame-render', this.boundHideSpinner)
    this.element.removeEventListener('click', this.boundHandlePaginationClick)
  }

  handlePaginationClick (event) {
    // Check if clicked element is a pagination link
    if (event.target.tagName === 'A' && event.target.href) {
      this.showSpinner()

      // Hide spinner after a delay as fallback
      setTimeout(() => {
        this.hideSpinner()
      }, 3000)
    }
  }

  showSpinner () {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove('hidden')
    }
  }

  hideSpinner () {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add('hidden')
    }
  }
}
