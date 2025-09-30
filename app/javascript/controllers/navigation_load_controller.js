import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['spinner']
  static values = {
    delay: { type: Number, default: 1000 },
    hiddenClass: { type: String, default: 'hidden' }
  }

  connect () {
    document.addEventListener('turbo:before-fetch-request', this.handleFetchRequest)
    document.addEventListener('turbo:before-render', this.handleBeforeRender)
  }

  disconnect () {
    document.removeEventListener('turbo:before-fetch-request', this.handleFetchRequest)
    document.removeEventListener('turbo:before-render', this.handleBeforeRender)

    // Clear any pending timeout
    clearTimeout(this.spinnerTimeout)
  }

  // Show spinner when Turbo starts fetching a full page navigation
  handleFetchRequest = (event) => {
    const target = event.target
    const isFullPageReload = target === document.documentElement || target === document.body || target === document

    // Check if this is a form submission by looking at the fetch method
    const isFormSubmission = event.detail?.fetchOptions?.method &&
                             event.detail.fetchOptions.method !== 'GET'

    // Check if this is a modal request by looking at Turbo frame target
    const requestUrl = event.detail?.url?.href || ''
    const isModalRequest = event.detail?.fetchOptions?.headers?.['Turbo-Frame'] ||
                          requestUrl.includes('/edit') ||
                          requestUrl.includes('/new') ||
                          target !== document.documentElement

    // Only show spinner for actual page navigation (GET requests that aren't modals or forms)
    if (isFullPageReload && !isFormSubmission && !isModalRequest) {
      // Clear any existing timeout to prevent race conditions
      clearTimeout(this.spinnerTimeout)

      this.spinnerTimeout = setTimeout(() => {
        if (this.hasSpinnerTarget) {
          this.spinnerTarget.classList.remove(this.hiddenClassValue)
        } else {
          console.warn('Navigation spinner target not found')
        }
      }, this.delayValue) // show spinner if page doesn't load after configured delay
    }
  }

  // Cancel spinner when Turbo is about to render new content
  handleBeforeRender = () => {
    clearTimeout(this.spinnerTimeout)
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add(this.hiddenClassValue)
    }
  }
}
