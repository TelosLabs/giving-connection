import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['subject', 'message']
  }

  subjectSelected() {
    if (this.subjectTarget.value === '1') {
      this.messageTarget.innerText = 'Hi, I’m interested in publishing my non profit on Giving Connection.'
    } else if (this.subjectTarget.value === '2') {
      this.messageTarget.innerText = 'Hi, I’m interested in claiming a non-profit profile already published on Giving Connection.'
    } else {
      return this.messageTarget.innerText = ''
    }
  }
}