import { Toggle } from "tailwindcss-stimulus-components";

export default class extends Toggle {
  static targets = ['toggleable']
  static values = { open: Boolean }

  toggle(event) {
    event.preventDefault()

    this.openValue = !this.openValue
  }

  hide(event) {
    event.preventDefault();

    this.openValue = false;
  }

  show(event) {
    event.preventDefault();

    this.openValue = true;
  }

  openValueChanged() {
    if (!this.toggleClass) { return }

    this.toggleableTargets.forEach(target => {
      target.classList.toggle(this.toggleClass)
    })
  }
}