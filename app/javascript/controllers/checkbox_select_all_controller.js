import CheckboxSelectAll from 'stimulus-checkbox-select-all'

export default class extends CheckboxSelectAll {

  connect() {
  }

  disconnect() {
  }

  toggle(e) {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = e.target.checked
    })
    document.querySelector("form").requestSubmit()
  }

  refresh() {
    this.checkboxAllTarget.checked = this.checked.length === this.checkboxTargets.length
  }
}
