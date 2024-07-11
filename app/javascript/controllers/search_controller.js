import { Controller } from "@hotwired/stimulus"
import { useDebounce, useDispatch } from 'stimulus-use'
import filterStore from "../utils/filterStore"

// TODO: Refactor controller
export default class extends Controller {
  static targets = [
    "keywordInput",
    "clearKeywordButton",
    "input",
    "customInput",
    "form",
    "pill",
    "radioButton",
    "advancedFilters",
    "pillsCounter",
    "pillsCounterWrapper",
    "filtersIcon"
  ]

  static debounces = ["displayClearKeywordButton"]

  initialize() {
    document.addEventListener("turbo:frame-load", () => {
      this.advancedFiltersButton = document.getElementById("advanced-filters-button")
      this.enableAdvancedFiltersButton(this.advancedFiltersButton)
    })
  }
  
  connect() {
    useDebounce(this, { wait: 250 });
    useDispatch(this)
    filterStore.clearFilters();
    this.updateRadioButtonsClass();
    filterStore.setInitialFilters(this.checkedFilters())
    if (filterStore.getFilters().length > 0) {
      this.updatePillsCounter()
    }
    
    window.addEventListener('location-updated', this.handleLocationUpdate.bind(this));
    window.addEventListener('filters-changed', this.handleFiltersChanged.bind(this));
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

  // Pills and radio buttons
  clearCheckedFilters() {
    this.advancedFiltersTarget.querySelectorAll("input:checked").forEach(input => input.click())
    this.pillTargets.forEach(input => {
      input.checked = false;
      input.removeAttribute('checked');
    });
    this.radioButtonTargets.forEach(radio => {
      radio.checked = false;
      radio.classList.remove("selected-button");
    })

    filterStore.clearFilters();
    this.updateFiltersState()
    this.submitForm()
  }

  checkedFilters() {
    let checkedFilters = this.pillTargets
                      .filter(pill => pill.checked)
                      .map(pill => pill.value === "true" ? pill.name : pill.value);
    if (this.radioButtonTargets.some(radio => radio.classList.contains("selected-button"))) {
      checkedFilters.push("distance")
    }
    return checkedFilters;
  }

  updateRadioButtonsClass() {
    this.radioButtonTargets.forEach(radio => {
      if (radio.checked === true) {
        radio.classList.add("selected-button");
      }
    })
  }

  updateCheckboxesFromFilterStore() {
    const filters = filterStore.getFilters();

    this.pillTargets.forEach(pill => {
      if (filters.includes(pill.value)) {
        pill.checked = true;
      } else if (pill.value === "true" && filters.includes(pill.name)) {
        pill.checked = true
      }
      else {
        pill.checked = false;
      }
    });
  }

  enableAdvancedFiltersButton(element) {
    element.classList.remove("text-gray-400")
    element.disabled = false
  }

  disableAdvancedFiltersButton(element) {
    element.classList.add("text-gray-400")
    element.disabled = true
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }

 togglePillsCounter(checkedPillsCount) {
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
    let count = filterStore.getFilters().length;
    this.pillsCounterTarget.textContent = count;
    this.togglePillsCounter(count);
  }

  updateFiltersState(event) {
    this.updatePillsCounter()
    if (this.advancedFiltersButton) {
      this.disableAdvancedFiltersButton(this.advancedFiltersButton)
    }
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

  clearAll() {
    if (this.isModalClean()) return

    const event = new CustomEvent('selectmultiple:clear', {})

    const anyFilterApplied = filterStore.getFilters().length > 0

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
      this.updateFiltersState()
      this.submitForm()
  }

  handleLocationUpdate(event) {
    this.submitForm();
  }

  toggleFilter(event) {
    const filter = this.filterName(event);
    if(filterStore.filters.has(filter)) {
      filterStore.removeFilter(filter);
    } else {
      filterStore.addFilter(filter);
    }
  }

  filterName(event) {
    if (event.target.name === "search[open_now]" || event.target.name === "search[open_weekends]") {
      return event.target.name;
    } else {
      return event.target.value
    }
  }

  toggleDistanceFilter(event) {
    const clickedPill = event.target;
    const filterValue = clickedPill.value;

    // If the clicked pill is already checked, uncheck it
    if (clickedPill.classList.contains("selected-button")) {
      clickedPill.checked = false;
      clickedPill.classList.remove("selected-button");
      filterStore.removeFilter("distance");
      this.uncheckAllDistancePills();
    } else {
      this.uncheckAllDistancePills();
      clickedPill.checked = true;
      clickedPill.classList.add("selected-button");
      filterStore.addFilter("distance");
    }
  }

  uncheckAllDistancePills() {
    this.radioButtonTargets.forEach(radio => {
      if (radio.name === "search[distance]") {
        radio.checked = false;
        radio.classList.remove("selected-button");
      }
    })
  }

  handleFiltersChanged(event) {
    this.updateFiltersState();
    this.updateCheckboxesFromFilterStore();
    this.updatePillsCounter();
  }

  disconnect() {
    window.removeEventListener('location-updated', this.handleLocationUpdate.bind(this));
    window.removeEventListener('filters-changed', this.handleFiltersChanged.bind(this));
  }
}
