import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = ["input", "container", "badgesContainer", 'checkbox', 'badgeTemplate']
  static values = { selected: Array }

  connect() {
    console.log('connected')
    this.store = new Set(this.selectedValue || [])
  }

  select(event) {
    this.addCheckboxToStore(event)
    this.updateBadges()
    console.log(this.store)
  }

  remove(event) {
    const value = event.currentTarget.parentElement.getAttribute('data-value')
    this.store.delete(value)
    console.log(value)
    // debugger
    this.updateCheckboxes()
    this.updateBadges()
  }

  focus() {
    console.log(this.inputTarget)
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

}