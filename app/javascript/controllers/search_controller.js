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
    // Unchecks applied advanced filters firing their data-actions, 
    // which clear displayed badges (see select_multiple_controller.js:15 and select-multiple component).
    this.advancedFiltersTarget.querySelectorAll("input:checked").forEach(input => input.click())
    this.pillsTarget.querySelectorAll("input:checked").forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })

    this.updatePillsCounter()
    this.pillsCounterDisplay()
  }

  updatePillsCounter() {
    // selects all checked inputs that are not checkboxAll
    this.totalChecked = document.querySelectorAll("input:checked").length - 1;
    this.pillsCounterTarget.textContent = this.totalChecked
    this.formTarget.requestSubmit()
  }

  pillsCounterDisplay() {
    if (this.totalChecked > 0) {
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

  clearAll() {
    if (this.isModalClean()) return

    const event = new CustomEvent('selectmultiple:clear', {})

    this.inputTargets.forEach(input => {
      this.clearInput(input)
    })
    this.customInputTargets.forEach(input => {
      input.dispatchEvent(event)
    })
    //Rails.fire(this.formTarget, 'submit')
    this.updatePillsCounter()
    this.pillsCounterDisplay()
  }

  openSearchAlertModal() {
    console.log('openSearchAlertModal')
    this.dispatch("openSearchAlertModal")
  }

  isModalClean() {
    return this.advancedFiltersTarget.querySelectorAll("input:checked").length === 0;
  }

  applyAdvancedFilters() {
    // gets the query string of the url
    const queryString = window.location.href.split('?')[1];
    // produces an array of values of the key/value pairs from the query string
    const values = [...new URLSearchParams(queryString).values()];
    console.log(values)
    // sets if there are new filters to apply
    const newFilters = [...this.advancedFiltersTarget.querySelectorAll("input:checked")].some(filter => !values.includes(filter.value));

    if (newFilters) {
      this.updatePillsCounter();
      this.pillsCounterDisplay();
    }
  }
}