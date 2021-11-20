import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["input", "container", "badgesContainer", 'checkbox', 'badgeTemplate', 'hiddenInput', 'group']
  static values = { selected: Array }

  connect() {
    console.log('connected')
    this.store = new Set(this.selectedValue || [])
    this.updateCheckboxes()
    this.updateBadges()
    this.updateHiddenInput()
    this.search()
  }

  select(event) {
    this.addCheckboxToStore(event)
    this.updateBadges()
    this.updateHiddenInput()
  }

  remove(event) {
    const value = event.currentTarget.parentElement.getAttribute('data-value')
    this.store.delete(value)

    this.updateCheckboxes()
    this.updateBadges()
    this.updateHiddenInput()
  }

  clearAll() {
    this.store.clear()
    console.log(this.store)
    this.updateCheckboxes()
    this.updateBadges()
    this.updateHiddenInput()
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
    const value = event.currentTarget.name
    if (event.currentTarget.checked) {
      this.store.add(value)
    } else {
      this.store.delete(value)
    }
  }

  updateCheckboxes() {
    this.checkboxTargets.forEach(checkbox => {
      if (this.store.has(checkbox.name)) {
        checkbox.checked = true
      } else {
        checkbox.checked = false
      }
    })
  }

  updateBadges() {
    this.badgesContainerTarget.innerHTML = ''
    this.store.forEach(value => {
      const badge = this.badgeTemplateTarget.cloneNode(true)
      const valueTarget = badge.querySelector('span')
      valueTarget.innerHTML = value
      badge.classList.remove('hidden')
      badge.setAttribute('data-value', value)
      this.badgesContainerTarget.appendChild(badge)
    })
  }

  updateHiddenInput() {
    this.hiddenInputTarget.value = Array.from(this.store)
  }

  search(event) {
    const query = this.inputTarget.value
    const regex = new RegExp('.*' + query.toLowerCase() + '.*', 'gmi')
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.name.search(regex) >= 0) {
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