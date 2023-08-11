import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clearSelection(event) {
    const checkedElement = document.querySelector(`input[name="${event.params.name}"]:checked`)
    if (checkedElement) {
      checkedElement.checked = false
    }
  }
}