import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clearSelection(event) {
    const checkedElement = event.currentTarget.parentElement.querySelector(('input[type="radio"]:checked'))
    if (checkedElement) {
      checkedElement.checked = false
    }
  }
}
