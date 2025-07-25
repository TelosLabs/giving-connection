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
    "filtersIcon",
    "panel",
    "tab",
    "searchPillsPanel"
  ] 

  static values = {
    currentExpandedCategory: String,
    isMobile: Boolean
  }

  static debounces = ["displayClearKeywordButton"]

  initialize() {
    document.addEventListener("turbo:frame-load", () => {
      this.advancedFiltersButton = document.getElementById("advanced-filters-button")
      this.enableAdvancedFiltersButton(this.advancedFiltersButton)
    })
    
    // Initialize with no expanded category
    this.currentExpandedCategoryValue = ''
    
    // Check if we're on mobile
    this.checkIfMobile()
    
    // Add resize listener to update mobile state
    window.addEventListener('resize', this.checkIfMobile.bind(this))
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

  disconnect() {
    window.removeEventListener('location-updated', this.handleLocationUpdate.bind(this));
    window.removeEventListener('filters-changed', this.handleFiltersChanged.bind(this));
    window.removeEventListener('resize', this.checkIfMobile.bind(this));
  }

  // Check if we're on mobile
  checkIfMobile() {
    const wasMobile = this.isMobileValue
    this.isMobileValue = window.innerWidth <= 768
    
    // Update the wrapper class when switching between mobile and desktop
    if (wasMobile !== this.isMobileValue && this.hasTabsWrapperTarget) {
      this.tabsWrapperTarget.classList.toggle('is-mobile', this.isMobileValue)
      
      // Reset state when switching between mobile and desktop
      this.collapseAllPanels()
      this.currentExpandedCategoryValue = ''
      this.searchPillsPanelTarget.classList.remove('expanded')
    }
  }

  // Handle tab hover for desktop
  handleTabHover(event) {
    if (this.isMobileValue) return
    
    const hoveredTab = event.currentTarget
    const categoryName = hoveredTab.textContent.trim()
    this.collapseAllPanels()
    this.expandPanel(categoryName)
  }

  // Handle mobile filter expansion
  toggleFilterCategory(event) {
    // Only handle click events on mobile
    if (!this.isMobileValue) return
    
    event.preventDefault()
    event.stopPropagation()

    const clickedTab = event.currentTarget
    const categoryName = clickedTab.textContent.trim()
    
    // If clicking the same category that's already expanded, collapse it
    if (this.currentExpandedCategoryValue === categoryName) {
      this.collapseAllPanels()
      this.currentExpandedCategoryValue = ''
      this.searchPillsPanelTarget.classList.remove('expanded')
      return
    }

    // Otherwise, expand the clicked category and collapse others
    this.collapseAllPanels()
    this.expandPanel(categoryName)
    this.currentExpandedCategoryValue = categoryName
    this.searchPillsPanelTarget.classList.add('expanded')
  }

  collapseAllPanels() {
    this.panelTargets.forEach(panel => {
      panel.classList.add('hidden')
    })
  }

  expandPanel(categoryName) {
    const panelIndex = this.tabTargets.findIndex(tab => 
      tab.textContent.trim() === categoryName
    )
    if (panelIndex >= 0) {
      this.panelTargets[panelIndex].classList.remove('hidden')
    }
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
                      .map(pill => ({ value: pill.value === "true" ? pill.name : pill.value, category: pill.name }));
    if (this.radioButtonTargets.forEach(radio =>  {
      if (radio.classList.contains("selected-button")) {
        checkedFilters.push({ value: radio.value, category: "distance" })
      }
    }));
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
      if (filters.some(filter => filter.value === pill.value && filter.category === pill.name)) {
        pill.checked = true;
      } else if (pill.value === "true" && filters.some(filter => filter.value === pill.name && filter.category === pill.name)) {
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
    if (this.pillsCounterTarget) {
      this.pillsCounterTarget.textContent = count;

    }
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
    this.element.dispatchEvent(event) // added dispatch to trigger listener in select multiple search controller

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
    const value = event.target.value;
    const category = event.target.name
    if(filterStore.hasFilter(value, category)) {
      filterStore.removeFilter(value, category);
    } else {
      filterStore.addFilter(value, category);
    }
  }

  // Distance

  toggleDistanceFilter(event) {
    const clickedPill = event.target;

    // If the clicked pill is already checked, uncheck it
    if (clickedPill.classList.contains("selected-button")) {
      clickedPill.checked = false;
      clickedPill.classList.remove("selected-button");
      this.clearDistanceFilters()
    } else {
      this.clearDistanceFilters()
      clickedPill.checked = true;
      clickedPill.classList.add("selected-button");
      filterStore.addFilter(clickedPill.value, "distance");
    }
  }

  clearDistanceFilters() {
    this.removeDistanceFiltersFromStore();
    this.uncheckAllDistancePills();
  }

  removeDistanceFiltersFromStore() {
    filterStore.getFilters().forEach(filter => {
      if (filter.category === "distance") {
        filterStore.removeFilter(filter.value, filter.category);
      }
    });
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
}
