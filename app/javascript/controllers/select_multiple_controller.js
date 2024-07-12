import { Controller } from "@hotwired/stimulus"
import filterStore from "../utils/filterStore"

export default class extends Controller {

  static targets = ["input", "container", "badgesContainer", 'checkbox', 'badgeTemplate', 'group', 'groupTitle']
  static values = { selected: Array }

  connect() {
    this.updateCheckboxes()
    this.updateBadges()
    this.search()
  }

  select(event) {
    this.addCheckboxToStore(event)
    this.updateBadges()
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

  focus() {
    this.inputTarget.classList.remove('hidden')
    this.inputTarget.focus()
    this.containerTarget.classList.add('border-blue-medium')
  }

  hide() {
    this.inputTarget.classList.add('hidden')
    this.containerTarget.classList.remove('border-blue-medium')
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
        const group = this.groupTargets.find(group => group.querySelector(`input[type="checkbox"][data-value="${value}"]`));
        if (group) {
          this.badgesContainerTarget.appendChild(badge);
        }
    });
  }

  search(event) {
    const query = this.inputTarget.value.toLowerCase()
    const regex = new RegExp('.*' + query + '.*', 'gmi')

    // Search checkboxes
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.dataset.value.search(regex) >= 0) {
        checkbox.parentElement.classList.remove('hidden')
      } else {
        checkbox.parentElement.classList.add('hidden')
      }
    })

    // Search group titles
    this.groupTitleTargets.forEach(groupTitle => {
      if (groupTitle.dataset.groupTitle.search(regex) >= 0) {
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
