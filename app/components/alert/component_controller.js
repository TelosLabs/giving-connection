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



  // close(event){
  //   this.element.classList.add('hidden', 'transition', 'transition-opacity', 'duration-1000');
  //   setTimeout(() => this.elementTarget.remove(), 1000)
  // }