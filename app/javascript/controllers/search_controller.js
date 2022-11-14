import { Controller } from "@hotwired/stimulus"
import { useDebounce, useDispatch } from 'stimulus-use'

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
    useDebounce(this)
    this.displayPillsCounter()
  }

  // Pills
  clearCheckedPills() {
    // Unchecks applied advanced filters firing their data-actions,
    // which clear displayed badges (see select_multiple_controller.js:15 and select-multiple component).
    this.advancedFiltersTarget.querySelectorAll("input:checked").forEach(input => input.click())
    this.pillsTarget.querySelectorAll("input:checked").forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })

    this.updatePillsCounter()
  }

  countPills() {
    // selects all checked inputs that are not checkboxAll
    this.totalChecked = document.querySelectorAll("input:checked").length - 1;
    this.pillsCounterTarget.textContent = this.totalChecked
    this.formTarget.requestSubmit()
  }

  displayPillsCounter() {
    if (this.totalChecked > 0) {
      this.pillsCounterWrapperTarget.classList.remove("hidden")
      this.filtersIconTarget.classList.add("hidden")
    }
    else {
      this.pillsCounterWrapperTarget.classList.add("hidden")
      this.filtersIconTarget.classList.remove("hidden")
    }
  }

  updatePillsCounter() {
    this.countPills()
    this.displayPillsCounter()
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

  checkedValues() {
    // gets the query string of the url
    const queryString = window.location.href.split('?')[1];
    // produces an array of values of the key/value pairs from the query string
    return [...new URLSearchParams(queryString).values()];
  }

  clearAll() {
    if (this.isModalClean()) return

    const event = new CustomEvent('selectmultiple:clear', {})

    const anyFilterApplied = [...this.advancedFiltersTarget.querySelectorAll("input:checked")].some(filter => this.checkedValues().includes(filter.value));

    this.inputTargets.forEach(input => {
      this.clearInput(input)
    })
    this.customInputTargets.forEach(input => {
      input.dispatchEvent(event)
    })

    if (anyFilterApplied) {
      this.updatePillsCounter()
    }
  }

  openSearchAlertModal() {
    console.log('openSearchAlertModal')
    this.dispatch("openSearchAlertModal")
  }

  isModalClean() {
    return this.advancedFiltersTarget.querySelectorAll("input:checked").length === 0;
  }

  applyAdvancedFilters() {
    const anyNewFilters = [...this.advancedFiltersTarget.querySelectorAll("input:checked")].some(filter => !this.checkedValues().includes(filter.value));

    if (anyNewFilters) {
      this.updatePillsCounter()
    }
  }
}