import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "searchAlert", "searchContent" ]
  }

  openSearchAlertModal() {
    this.searchAlertTarget.classList.remove('hidden')
    this.searchContentTarget.classList.add('search-modal-slide-in')
    this.searchContentTarget.classList.remove('search-modal-slide-out')
    document.body.classList.add('overflow-hidden')
  }

  collapseSearchAlertModal() {
    this.searchContentTarget.classList.remove('search-modal-slide-in')
    this.searchContentTarget.classList.add('search-modal-slide-out')
    document.body.classList.remove('overflow-hidden')
    setTimeout(() => {
      this.searchAlertTarget.classList.add('hidden')
    }, 400);
  }
}