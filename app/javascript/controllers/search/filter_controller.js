import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['input', 'customInput']
  }

  clearAll() {
    const event = new CustomEvent('selectmultiple:clear', {  })

    this.inputTargets.forEach(input => {
      this.clearInput(input)
    })
    this.customInputTargets.forEach(input => {
      input.dispatchEvent(event)
    })
  }

  clearInput(inputElem) {
    const inputType = inputElem.type.toLowerCase()
    switch (inputType) {
      case 'text':
      case 'password':
      case 'textarea':
      case 'search':
      case 'hidden':
      case 'date':
        inputElem.value = ''
        break
      case 'radio':
        inputElem.checked = inputElem.hasAttribute('checked')
        break
      case 'checkbox':
        inputElem.checked = false
        inputElem.removeAttribute('checked')
        break
      default:
        break
    }
  }
}