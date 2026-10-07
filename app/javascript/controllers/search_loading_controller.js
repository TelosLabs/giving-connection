import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['spinner', 'resultsContainer']

  connect () {
    this.handleBeforeFetch = this.onBeforeFetch.bind(this)
    this.handleFrameRender = this.onFrameRender.bind(this)
    this.handleFrameLoad = this.onFrameLoad.bind(this)

    document.addEventListener('turbo:before-fetch-request', this.handleBeforeFetch)
    document.addEventListener('turbo:frame-render', this.handleFrameRender)
    document.addEventListener('turbo:frame-load', this.handleFrameLoad)
  }

  disconnect () {
    document.removeEventListener('turbo:before-fetch-request', this.handleBeforeFetch)
    document.removeEventListener('turbo:frame-render', this.handleFrameRender)
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad)
  }

  onBeforeFetch (event) {
    if (!this.isRelevant(event)) return

    this.scrollToTop()
    this.showSpinner()
  }

  onFrameRender (event) {
    if (!this.isRelevant(event)) return

    this.hideSpinner()
  }

  onFrameLoad (event) {
    if (!this.isRelevant(event)) return

    this.hideSpinner()
  }

  // True when `event` is a navigation that updates THIS frame -- whether it
  // was triggered by a link/form inside the frame (event.target is the
  // frame itself, or a descendant) or by an external element explicitly
  // targeting it (event.target carries a matching data-turbo-frame).
  isRelevant (event) {
    const target = event.target
    if (!target) return false
    if (target === this.element) return true
    if (typeof target.contains === 'function' && this.element.contains(target)) return true

    return !!target.getAttribute && target.getAttribute('data-turbo-frame') === this.element.id
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
