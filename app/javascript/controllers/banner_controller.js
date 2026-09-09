import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ["banner"]
  }

  static get values() {
    return { key: { type: String, default: "banner-session" } }
  }

  initialize() {
    if (sessionStorage.getItem(this.keyValue) == 'user-closed') {
      this.bannerTarget.classList.add('hidden')
    }
  }

  closeBanner() {
    sessionStorage.setItem(this.keyValue, 'user-closed')
    this.bannerTarget.classList.add('hidden')
  }
}
