import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    new TomSelect(this.element, {
      plugins: {
        'remove_button': {
          title: 'Remove this item',
        }
      },
      placeholder: this.element.dataset.placeholder || "Select options...",
      persist: false,
      create: false,
      maxItems: null, // Allow unlimited selections
      hideSelected: true, // Hide selected items from dropdown
      closeAfterSelect: false, // Keep dropdown open after selecting
    })
  }
}