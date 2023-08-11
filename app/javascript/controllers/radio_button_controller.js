import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clearSelection(event) {
    // use the name param to specify the button group from which you want to clear selection
    const checkedElement = document.querySelector(`input[name="${event.params.name}"]:checked`)
    if (checkedElement) {
      checkedElement.checked = false
    }
  }
}
