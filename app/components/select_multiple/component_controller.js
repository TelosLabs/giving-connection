import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "container", "badgesContainer", 'checkbox', 'badgeTemplate', 'group', ]

  connect() {
    // Map of submitted value -> display label. For most fields (Causes,
    // Services, Populations) value and label are the same string. Fields
    // backed by a stable key + display label (e.g. In-Kind Donation Needs)
    // set a separate data-label so badges show the human-readable text
    // instead of the raw stored key.
    this.store = new Map()
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.checked) {
        this.store.set(checkbox.dataset.value, this.labelFor(checkbox))
      }
    })
    this.updateBadges()
  }

  labelFor(checkbox) {
    return checkbox.dataset.label || checkbox.dataset.value
  }

  select(event) {
    this.addCheckboxToStore(event)
    this.updateBadges()
  }

  remove(event) {
    const value = event.currentTarget.parentElement.getAttribute('data-value')
    this.store.delete(value)

    this.updateCheckboxes()
    this.updateBadges()
  }

  clearAll() {
    this.store.clear()
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
    const checkbox = event.currentTarget
    const value = checkbox.dataset.value
    if (checkbox.checked) {
      this.store.set(value, this.labelFor(checkbox))
    } else {
      this.store.delete(value)
    }
  }

  updateCheckboxes() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = this.store.has(checkbox.dataset.value)
    })
  }

  updateBadges() {
    this.badgesContainerTarget.innerHTML = ''
    this.store.forEach((label, value) => {
      const badge = this.badgeTemplateTarget.cloneNode(true)
      const valueTarget = badge.querySelector('span')
      valueTarget.textContent = label
      badge.classList.remove('hidden')
      badge.setAttribute('data-value', value)
      this.badgesContainerTarget.appendChild(badge)
    })
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

  search(event) {
    const query = this.inputTarget.value.toLowerCase()
    const regex = new RegExp('.*' + query + '.*', 'gmi')

    this.checkboxTargets.forEach(checkbox => {
      if (this.labelFor(checkbox).search(regex) >= 0) {
        checkbox.parentElement.classList.remove('hidden')
      } else {
        checkbox.parentElement.classList.add('hidden')
      }
    })
    this.updateGroups()
  }
}
