import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "backdrop"]

  close() {
    this.element.remove();
  }

  closeAfterSubmit(event) {
    if (event.detail.success) {
      this.close();
    }
  }
}
