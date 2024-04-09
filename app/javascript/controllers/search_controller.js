import { Controller } from "@hotwired/stimulus"
import { useDebounce, useDispatch } from 'stimulus-use'

// TODO: Refactor controller
export default class extends Controller {
  static targets = [
    "keywordInput",
    "clearKeywordButton",
    "input",
    "customInput",
    "form",
    "pill",
    "advancedFilters",
    "pillsCounter",
    "pillsCounterWrapper",
    "filtersIcon"
  ]

  static debounces = ["displayClearKeywordButton"]

  connect() {
    useDebounce(this, { wait: 250 });
    useDispatch(this)
    if (this.hasPillTarget) {
      this.updatePillsCounter()
      this.updateRadioButtonsClass()
    }

    window.addEventListener('locationUpdated', this.handleLocationUpdate.bind(this));
  }

  initialize() {
    document.addEventListener("turbo:frame-load", () => {
      this.advancedFiltersButton = document.getElementById("advanced-filters-button")
      this.enableAdvancedFiltersButton(this.advancedFiltersButton)
    })
  }

  // Keyword

  displayClearKeywordButton() {
    const classListAction = this.keywordInputTarget.value ? "remove" : "add";
    this.clearKeywordButtonTarget.classList[classListAction]("hidden");
  }

  clearKeywordInput() {
    const inputValue = this.keywordInputTarget.value;

    if (!inputValue) return;

    this.keywordInputTarget.value = "";
    this.clearKeywordButtonTarget.classList.add("hidden");

    if (this.keywordParamEqualsInputValue(inputValue)) {
      this.submitForm();
    }
  }

  keywordParamEqualsInputValue(inputValue) {
    const url = new URL(window.location.href);
    const keywordParam = url.searchParams.get("search[keyword]");
    return keywordParam === inputValue;
  }

  // Pills
  clearCheckedPills() {
    // Unchecks applied advanced filters firing their data-actions,
    // which clear displayed badges (see select_multiple_controller.js:15 and select-multiple component).
    this.advancedFiltersTarget.querySelectorAll("input:checked").forEach(input => input.click())
    this.pillTargets.forEach(input => {
      input.checked = false;
      input.removeAttribute('checked');
    });

    this.updateFiltersState()
    this.submitForm()
  }

  enableAdvancedFiltersButton(element) {
    element.classList.remove("text-gray-400")
    element.disabled = false
  }

  disableAdvancedFiltersButton(element) {
    element.classList.add("text-gray-400")
    element.disabled = true
  }

  countPills() {
    const checkedPills = this.pillTargets.filter(pill => pill.checked);
    this.pillsCounterTarget.textContent = checkedPills.length;
    return checkedPills.length;
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }

  displayPillsCounter(checkedPillsCount) {
    if (checkedPillsCount > 0) {
      this.pillsCounterWrapperTarget.classList.remove("hidden")
      this.filtersIconTarget.classList.add("hidden")
    }
    else {
      this.pillsCounterWrapperTarget.classList.add("hidden")
      this.filtersIconTarget.classList.remove("hidden")
    }
  }

  updatePillsCounter() {
    this.displayPillsCounter(this.countPills());
  }

  updateFiltersState() {
    this.updatePillsCounter()
    if (this.advancedFiltersButton) {
      this.disableAdvancedFiltersButton(this.advancedFiltersButton)
    }
  }

  updateRadioButtonsClass() {
    const buttons = document.querySelectorAll('input[name="search[distance]"]')
    const buttons_array = [...buttons]
    buttons_array.forEach(button => {
      if (button.checked) {
        button.classList.add("selected-button")
      }
    })
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

  toggleRadioButton(event) {
    let button = event.target
    if (button.classList.contains("selected-button")) {
      button.checked = false
      button.classList.remove("selected-button")
    } else {
      button.checked = true
      button.classList.add("selected-button")
    }
    this.updateFiltersState()
    this.submitForm()
  }

  handleLocationUpdate(event) {
    this.submitForm();
  }

  disconnect() {
    window.removeEventListener('locationUpdated', this.handleLocationUpdate.bind(this));
  }
}
