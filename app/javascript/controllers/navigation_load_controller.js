import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener('turbo:before-fetch-request', this.handleFetchRequest)
    document.addEventListener('turbo:before-render', this.handleBeforeRender)
  }

  disconnect() {
    document.removeEventListener('turbo:before-fetch-request', this.handleFetchRequest)
    document.removeEventListener('turbo:before-render', this.handleBeforeRender)

    this.element.querySelectorAll('a').forEach(link => {
      if (!this.isLocalLink(link)) {
        link.removeEventListener('click', this.scrollToTop)
      }
    })
  }

  // Show spinner when Turbo starts fetching a full page navigation
  handleFetchRequest = (event) => {
    const target = event.target
    const isFullPageReload = target === document.documentElement || target === document.body || target === document

    if (isFullPageReload) {
      this.spinnerTimeout = setTimeout(() => {
        const spinner = document.getElementById("global-spinner")
        if (spinner) spinner.classList.remove("hidden")
      }, 1000) // show spinner if page doesn't load after 1 second
    }
  }

  // Cancel spinner when Turbo is about to render new content
  handleBeforeRender = () => {
    clearTimeout(this.spinnerTimeout)
    const spinner = document.getElementById("global-spinner")
    if (spinner) spinner.classList.add("hidden")
  }

  isLocalLink(link) {
    return (
      link.hostname === window.location.hostname &&
      !link.href.startsWith('mailto:') &&
      !link.href.startsWith('tel:') &&
      !link.hash 
    )
  }
}
