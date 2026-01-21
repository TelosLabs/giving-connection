import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['spinner', 'resultsContainer']

  connect () {
    // Store bound functions for proper cleanup
    this.handleBeforeFetch = this.onBeforeFetch.bind(this)
    this.handleFrameRender = this.onFrameRender.bind(this)
    this.handleFrameLoad = this.onFrameLoad.bind(this)

    // Listen for Turbo Frame events
    this.element.addEventListener('turbo:before-fetch-request', this.handleBeforeFetch)
    this.element.addEventListener('turbo:frame-render', this.handleFrameRender)
    this.element.addEventListener('turbo:frame-load', this.handleFrameLoad)
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-fetch-request', this.handleBeforeFetch)
    this.element.removeEventListener('turbo:frame-render', this.handleFrameRender)
    this.element.removeEventListener('turbo:frame-load', this.handleFrameLoad)
  }

  onBeforeFetch () {
    this.scrollToTop()
    this.showSpinner()
  }

  onFrameRender () {
    this.hideSpinner()
  }

  onFrameLoad () {
    this.hideSpinner()
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
      this.resultsContainerTarget.scrollTo({ top: 0, behavior: 'smooth' })
    }
    
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}