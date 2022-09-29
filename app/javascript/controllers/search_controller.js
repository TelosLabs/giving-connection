import { Controller } from "@hotwired/stimulus"
import { useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['input', 'customInput', 'form', 'pills', "pillsCounter"]
  }

  connect() {
    useDispatch(this)
  }

  clearAll() {
    const event = new CustomEvent('selectmultiple:clear', {  })

    this.inputTargets.forEach(input => {
      this.clearInput(input)
    })
    this.customInputTargets.forEach(input => {
      input.dispatchEvent(event)
    })
    Rails.fire(this.formTarget, 'submit')
  }

  clearInput(inputElement) {
    console.log(inputElement)
    const inputType = inputElement.type.toLowerCase()
    switch (inputType) {
      case 'text':
      case 'password':
      case 'textarea':
      case 'search':
      case 'hidden':
      case 'date':
        inputElement.value = ''
        break
      case 'radio':
        inputElement.checked = inputElement.hasAttribute('checked')
        break
      case 'checkbox':
        inputElement.checked = false
        inputElement.removeAttribute('checked')
        break
      case 'select-one':
      case 'select-multi':
        inputElement.selectedIndex = -1
        break
      default:
        break
    }
  }

  openSearchAlertModal() {
    console.log('openSearchAlertModal')
    this.dispatch("openSearchAlertModal")
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }

  clearChecked() {
    this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })
    this.pillsTarget.querySelectorAll('input[type="radio"]:checked').forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })
    this.pillsCounterTarget.innerHTML = ""
    this.submitForm()
  }

  updatePillsCounter() {
    let checks = this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').length
    let radio = this.pillsTarget.querySelectorAll('input[type="radio"]:checked').length
    this.pillsCounterTarget.innerHTML = checks + radio
  }
}
