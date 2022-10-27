import { Controller } from "@hotwired/stimulus"
import { useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return [
      'input',
      'customInput',
      'form',
      'pills',
      "pillsCounter",
      "pillsCounterWrapper",
      "filtersIcon",
      "causesPill",
      "servicesPill",
      "beneficiaryGroupsPill",
      "selectAllCausesPill",
      "selectAllServicesPill",
      "selectAllBeneficiaryGroupsPill"
    ]
  }

  connect() {
    useDispatch(this)
    this.updatePillsCounter()
    this.managePillsCounterDisplay()
  }

  clearAll() {
    const event = new CustomEvent('selectmultiple:clear', {})

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
    this.updatePillsCounter()
    this.managePillsCounterDisplay()
    this.submitForm()
  }

  updatePillsCounter() {
    const checks = this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').length
    const radio = this.pillsTarget.querySelectorAll('input[type="radio"]:checked').length
    this.totalChecked = checks + radio
    this.pillsCounterTarget.textContent = this.totalChecked
  }

  managePillsCounterDisplay() {
    if (this.totalChecked > 0) {
      this.pillsCounterWrapperTarget.classList.remove("hidden")
      this.pillsCounterWrapperTarget.classList.add("inline-flex")
      this.filtersIconTarget.classList.add("hidden")
    }
    else {
      this.pillsCounterWrapperTarget.classList.add("hidden")
      this.pillsCounterWrapperTarget.classList.remove("inline-flex")
      this.filtersIconTarget.classList.remove("hidden")
    }
  }

  //Checks if the selectAllPill of a given panel is checked. If that's the case, then unchecks it.
  manageAllPillCheck(e) {
    const filterPillName = e.target.getAttribute("name")
    let allButton

    if (filterPillName.includes("search[causes]")) {
      allButton = this.selectAllCausesPillTarget
    }
    else if (filterPillName.includes("search[services]")) {
      allButton = this.selectAllServicesPillTarget
    }
    else if (filterPillName.includes("search[beneficiary_groups]")) {
      allButton = this.selectAllBeneficiaryGroupsPillTarget
    }

    if (allButton.checked) {
      allButton.checked = false
      allButton.removeAttribute("checked")
    }
  }

  toggleAllPills(e) {
    const allButtonName = e.target.getAttribute("name")
    let pillsArray

    if (allButtonName === "causes_all") {
      pillsArray = this.causesPillTargets
    }
    else if (allButtonName === "services_all") {
      pillsArray = this.servicesPillTargets
    }
    else if (allButtonName === "groups_all") {
      pillsArray = this.beneficiaryGroupsPillTargets
    }

    if (this.allPillsAreChecked(pillsArray) && !e.target.checked) {
      pillsArray.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    }
    else {
      pillsArray.filter(pill => pill.checked === false).forEach(uncheckedPill => {
        uncheckedPill.checked = true
        uncheckedPill.setAttribute('checked', true)
      })
    }
    this.updatePillsCounter()
    this.managePillsCounterDisplay()
    this.submitForm()
  }

  allPillsAreChecked(pills) {
    return pills.every(pill => pill.checked)
  }
}
