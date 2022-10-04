import { Controller } from "@hotwired/stimulus"
import { useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['input', 'customInput', 'form', 'pills', "pillsCounter", "causesPill", "servicesPill", "beneficiaryGroupsPill"]
  }

  connect() {
    useDispatch(this)
  }

  toggleAllCausesPills() {
    if (this.allPillsAreChecked(this.causesPillTargets)) {
      this.causesPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.causesPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.updatePillsCounter()
    this.submitForm()
  }

  toggleAllServicesPills() {
    this.servicesPillTargets.forEach(pill => {
      if (pill.checked) {
        pill.checked = false
        pill.removeAttribute('checked')
      } else {
      pill.checked = true
      pill.setAttribute('checked', true)
      }
    })
    this.updatePillsCounter()
    this.submitForm()
  }

  toggleAllBeneficiaryGroupsPills() {
    this.beneficiaryGroupsPillTargets.forEach(pill => {
      if (pill.checked) {
        pill.checked = false
        pill.removeAttribute('checked')
      } else {
      pill.checked = true
      pill.setAttribute('checked', true)
      }
    })
    this.updatePillsCounter()
    this.submitForm()
  }

  allPillsAreChecked(pills) {
    let checked_pills = []
    pills.forEach(pill => {
      if (pill.checked) {
        checked_pills.push(pill)
      }
    })
    return checked_pills.length == pills.length
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
