import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['spinner', 'resultsContainer']

  connect () {
    this.element.addEventListener('turbo:before-fetch-request', () => {
      this.scrollToTop()
      this.showSpinner()
    })
    
    this.element.addEventListener('turbo:frame-render', () => {
      this.hideSpinner()
    })
    
    this.element.addEventListener('turbo:frame-load', () => {
      this.hideSpinner()
    })
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

  scrollToTop () {
    if (this.hasResultsContainerTarget) {
      this.resultsContainerTarget.scrollTop = 0
    }
    
    window.scrollTo({ top: 0, behavior: 'instant' })
  }
}