import { Controller } from "stimulus"

export default class extends Controller {
  static get targets() {
    return ['subject', 'message']
  }

  subjectSelected() {
    if (this.subjectTarget.value === 'I want to publish a non profit on Giving Connection') {
      this.messageTarget.value = 'Hi, I’m interested in publishing my non profit on Giving Connection.'
    }
    if (this.subjectTarget.value === 'I want to claim ownership of a non profit page') {
      this.messageTarget.value = 'Hi, I’m interested in claiming a non-profit profile already published on Giving Connection.'
    }
    if (this.subjectTarget.value === ('' || 'Other')) {
      this.messageTarget.value = ''
    }
  }
}