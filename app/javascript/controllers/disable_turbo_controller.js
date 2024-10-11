import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = { targetUrls: Array }

  disableTurboForTargetUrls(event) {
    if (this.targetUrlsValue.includes(event.detail.url)) {
      event.preventDefault();
    }
  }
}
