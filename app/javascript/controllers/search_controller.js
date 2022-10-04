import { Controller } from "@hotwired/stimulus"
import { useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['input', 'customInput', 'form', 'pills', "pillsCounter", "causesPill", "servicesPill", "beneficiaryGroupsPill", "selectAllCausesPill", "selectAllServicesPill", "selectAllBeneficiaryGroupsPill"]
  }

  connect() {
    useDispatch(this)
  }

  toggleAllCausesPills() {
    if (this.allPillsAreChecked(this.causesPillTargets) == "allSelected") {
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
    this.submitForm()
    this.updatePillsCounter()
  }

  toggleAllServicesPills() {
    if (this.allPillsAreChecked(this.servicesPillTargets) == "allSelected") {
      this.servicesPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.servicesPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.submitForm()
    this.updatePillsCounter()
  }

  toggleAllBeneficiaryGroupsPills() {
    if (this.allPillsAreChecked(this.beneficiaryGroupsPillTargets) == "allSelected") {
      this.beneficiaryGroupsPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.beneficiaryGroupsPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.submitForm()
    this.updatePillsCounter()
  }

  allPillsAreChecked(pills) {
    let checked_pills = []
    pills.forEach(pill => {
      if (pill.checked) {
        checked_pills.push(pill)
      }
    })
    if (checked_pills.length == pills.length) {
      return "allSelected"
    } else if (checked_pills.length == 0) {
      return "noneSelected"
    } else if (checked_pills.length > 0 && checked_pills.length < pills.length) {
      return "someSelected"
    }
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
    if (this.allPillsAreChecked(this.causesPillTargets) == "someSelected") {
      this.selectAllCausesPillTarget.checked = false
      this.selectAllCausesPillTarget.removeAttribute('checked')
    }
    if (this.allPillsAreChecked(this.servicesPillTargets) == "someSelected") {
      this.selectAllServicesPillTarget.checked = false
      this.selectAllServicesPillTarget.removeAttribute('checked')
    }
    if (this.allPillsAreChecked(this.beneficiaryGroupsPillTargets) == "someSelected") {
      this.selectAllBeneficiaryGroupsPillTarget.checked = false
      this.selectAllBeneficiaryGroupsPillTarget.removeAttribute('checked')
    }
  }
}
