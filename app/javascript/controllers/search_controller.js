import { Controller } from "@hotwired/stimulus"
import { useDebounce, useDispatch } from 'stimulus-use'

export default class extends Controller {
  static debounces = ['enableAdvancedFiltersButton']
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
    useDebounce(this, { wait: 2700 })
    this.updateFiltersState()
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

    this.updateFiltersState()
    this.submitForm()
  }

  enableAdvancedFiltersButton(element) {
    element.classList.remove("text-gray-400")
    element.disabled = false
  }

  disableAdvancedFiltersButton() {
    this.advancedFiltersButton.disabled = true
    this.advancedFiltersButton.classList.add("text-gray-400")
  }

  countPills() {
    // selects all checked inputs that are not checkboxAll
    this.totalChecked = document.querySelectorAll("input:checked").length - 1;
    this.pillsCounterTarget.textContent = this.totalChecked
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }

  manageAdvancedFiltersButton() {
    this.advancedFiltersButton = document.getElementById("advanced-filters-button")
    this.disableAdvancedFiltersButton(this.advancedFiltersButton)
    this.enableAdvancedFiltersButton(this.advancedFiltersButton)
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

  updateFiltersState() {
    this.updatePillsCounter()
    this.manageAdvancedFiltersButton()
  }

  // Modal
  clearInput(inputElement) {
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
      this.updateFiltersState()
      this.submitForm()
    }
  }

  openSearchAlertModal() {
    this.dispatch("openSearchAlertModal")
  }

  isModalClean() {
    return this.advancedFiltersTarget.querySelectorAll("input:checked").length === 0;
  }

  applyAdvancedFilters() {
    const anyNewFilters = [...this.advancedFiltersTarget.querySelectorAll("input:checked")].some(filter => !this.checkedValues().includes(filter.value));

    if (anyNewFilters) {
      this.updateFiltersState()
      this.submitForm()
    }
  }
}
