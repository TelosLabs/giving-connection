import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "banner" ]
  }

  initialize() {
    console.log(sessionStorage.getItem('banner-session'))
    if (sessionStorage.getItem('banner-session') === 'inactive' ) {
      this.bannerTarget.classList.toggle('hidden')
    }
  }

  closeBanner() {
    sessionStorage.setItem('banner-session', 'user-closed')
    this.bannerTarget.classList.toggle('hidden')
  }
}
