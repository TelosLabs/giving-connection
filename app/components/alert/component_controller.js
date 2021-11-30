import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "notification" ]
  } 

  closeAlert() {
    this.notificationTarget.remove()
  }
}