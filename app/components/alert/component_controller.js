import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "notification" ]
  } 

  connect() {
    setTimeout(() =>
      this.notificationTarget.remove(), 10000)
  }

  closeAlert() {
    this.notificationTarget.remove()
  }
}
