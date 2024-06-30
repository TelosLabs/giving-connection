import { Controller } from "@hotwired/stimulus"
import filterStore from "../utils/filterStore"

export default class extends Controller {

  static targets = ["input", "container", "badgesContainer", 'checkbox', 'badgeTemplate', 'group']
  static values = { selected: Array }

  connect() {
    this.store = filterStore.filters
    this.updateCheckboxes()
    this.updateBadges()
    this.search()
  }

  select(event) {
    this.addCheckboxToStore(event)
    this.updateBadges()
  }

  remove(event) {
    const value = event.currentTarget.parentElement.getAttribute('data-value')
    filterStore.removeFilter(value)

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
    const value = event.currentTarget.dataset.value

    if (event.currentTarget.checked) {
      filterStore.addFilter(value)
    } else {
      filterStore.removeFilter(value)
    }
  }

  updateCheckboxes() {
    const changeEvent = new Event("change", { bubbles: true })

    this.checkboxTargets.forEach(checkbox => {
      if (this.store.has(checkbox.dataset.value)) {
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

    if (this.store.size == 0 && this.inputTarget.id == 'required') {
      this.inputTarget.setAttribute('required', true)
    } else if (this.inputTarget.hasAttribute('required')) {
      this.inputTarget.removeAttribute('required')
    }

    this.store.forEach(value => {
        const badge = this.badgeTemplateTarget.cloneNode(true);
        const valueTarget = badge.querySelector('span');
        valueTarget.innerHTML = value;
        badge.classList.remove('hidden');
        badge.setAttribute('data-value', value);

        // Find the group container for the badge
        const group = this.groupTargets.find(group => group.querySelector(`[data-value="${value}"]`));
        if (group) {
          this.badgesContainerTarget.appendChild(badge);
        }
    });
  }

  search(event) {
    const query = this.inputTarget.value
    const regex = new RegExp('.*' + query.toLowerCase() + '.*', 'gmi')
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.dataset.value.search(regex) >= 0) {
        checkbox.parentElement.classList.remove('hidden')
      } else {
        checkbox.parentElement.classList.add('hidden')
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
