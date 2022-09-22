import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "banner" ]
  }

  initialize() {
    console.log(sessionStorage.getItem('banner-session'))
    if (sessionStorage.getItem('banner-session') != 'user-closed') {
      this.bannerTarget.classList.remove('hidden')
    }
  }

  closeBanner() {
    sessionStorage.setItem('banner-session', 'user-closed')
    this.bannerTarget.classList.add('hidden')
  }
}
