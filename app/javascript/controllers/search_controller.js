import { Controller } from "@hotwired/stimulus"
import { useDebounce, useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static debounces = ['submitForm']
  static get targets() {
    return [
      "input",
      "customInput",
      "form",
      "pills",
      "advancedFilters",
      "pillsCounter",
      "pillsCounterWrapper",
      "filtersIcon",
      "clearAllButton",
      "advancedFiltersCheckboxes"
    ]
  }

  connect() {
    useDispatch(this)
    this.updatePillsCounter()
    this.pillsCounterDisplay()
    useDebounce(this)
    this.pillsCounterDisplay()
  }
  // Pills
  clearChecked() {
    this.advancedFiltersTarget.querySelectorAll("input:checked").forEach(input => input.click())
    this.pillsTarget.querySelectorAll("input:checked").forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })

    this.updatePillsCounter()
    this.pillsCounterDisplay()
    //this.formTarget.requestSubmit()
  }

  updatePillsCounter() {
    // selects all checked inputs that are not checkboxAll
    this.totalChecked = document.querySelectorAll("input:checked").length;
    this.pillsCounterTarget.textContent = this.totalChecked - 1
    this.formTarget.requestSubmit()
  }

  pillsCounterDisplay() {
    if (this.totalChecked - 1 > 0) {
      this.pillsCounterWrapperTarget.classList.remove("hidden")
      this.filtersIconTarget.classList.add("hidden")
    }
    else {
      this.pillsCounterWrapperTarget.classList.add("hidden")
      this.filtersIconTarget.classList.remove("hidden")
    }
  }
  // Modal
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



  clearAll(e) {
    const event = new CustomEvent('selectmultiple:clear', {})

    this.inputTargets.forEach(input => {
      this.clearInput(input)
    })
    this.customInputTargets.forEach(input => {
      input.dispatchEvent(event)
    })
    // if (e.target == this.clearAllButtonTarget) {
    Rails.fire(this.formTarget, 'submit')
    // }
  }

  openSearchAlertModal() {
    console.log('openSearchAlertModal')
    this.dispatch("openSearchAlertModal")
  }
}
