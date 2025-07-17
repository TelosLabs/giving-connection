import filterStore from "../utils/filterStore"
import SelectMultipleController from "./../../components/select_multiple/component_controller"

export default class extends SelectMultipleController {
  static targets = SelectMultipleController.targets.concat("groupTitle")

  connect() {
    // Listen for event to clear all filters
    this.element.addEventListener('selectmultiple:clear', () => this.clearAll())
    this.updateCheckboxes()
    this.updateBadges()
    this.search()
  }

  remove(event) {
    const badge = event.currentTarget.parentElement

    filterStore.removeFilter(badge.dataset.value, badge.dataset.category)

    this.updateCheckboxes()
    this.updateBadges()
  }

  clearAll() {
    filterStore.clearFilters()
    this.updateCheckboxes()
    this.updateBadges()
  }

  addCheckboxToStore(event) {
    const value = event.target.value
    const category = event.target.name

    if (event.currentTarget.checked) {
      filterStore.addFilter(value, category)
    } else {
      filterStore.removeFilter(value, category)
    }
  }

  updateCheckboxes() {
    const changeEvent = new Event("change", { bubbles: true })

    this.checkboxTargets.forEach(checkbox => {
      const value = checkbox.value
      const category = checkbox.name

      if (filterStore.hasFilter(value, category)) {
        checkbox.checked = true
      } else {
        checkbox.checked = false
      }

      if (checkbox.checked !== checkbox.defaultChecked) {
        checkbox.dispatchEvent(changeEvent)
      }
    })
    this.search()
  }

  updateBadges() {
    this.badgesContainerTarget.innerHTML = ''

    if (filterStore.getFilters().length == 0 && this.inputTarget.id == 'required') {
      this.inputTarget.setAttribute('required', true)
    } else if (this.inputTarget.hasAttribute('required')) {
      this.inputTarget.removeAttribute('required')
    }

    filterStore.getFilters().forEach(({ value, category }) => {
      const badge = this.badgeTemplateTarget.cloneNode(true);
      const valueTarget = badge.querySelector('span');
      valueTarget.innerHTML = value;
      badge.classList.remove('hidden');
      badge.setAttribute('data-value', value);
      badge.setAttribute('data-category', category);

        // Find the group container for the badge
        const group = this.groupTargets.find(group => group.querySelector(`input[type="checkbox"][data-value="${value}"][name="${category}"]`));
        if (group) {
          this.badgesContainerTarget.appendChild(badge);
        }
    });
  }

  search(event) {
    super.search()
    // Search group titles
    this.groupTitleTargets.forEach(groupTitle => {
      if (groupTitle.dataset.groupTitle.includes(this.inputTarget.value)) {
        groupTitle.parentElement.classList.remove('hidden')
        groupTitle.parentElement.querySelectorAll('div').forEach(div => div.classList.remove('hidden'))
      } else {
        groupTitle.parentElement.classList.add('hidden')
      }
    })

    this.updateGroups()
  }

  updateGroups() {
    this.groupTargets.forEach(group => {
      const groupChecked = group.querySelectorAll('div:not(.hidden) > input[type="checkbox"]')
      if (groupChecked.length > 0) {
        group.classList.remove('hidden')
      } else {
        group.classList.add('hidden')
      }
    })
  }
}
