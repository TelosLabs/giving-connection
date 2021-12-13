import { Dropdown } from "tailwindcss-stimulus-components";

// Extend Dropdown to close it when you press ESC.

export default class extends Dropdown {
  initialize() {
    this.keyboardListener = this.keyboardListener.bind(this);
    this.activeIndex = 0;
  }

  connect() {
    this.toggleClass = this.data.get('class') || 'hidden'
    this.visibleClass = this.data.get('visibleClass') || null
    this.invisibleClass = this.data.get('invisibleClass') || null
    this.activeClass = this.data.get('activeClass') || null
    this.enteringClass = this.data.get('enteringClass') || null
    this.leavingClass = this.data.get('leavingClass') || null
    if (this.hasButtonTarget) {
      this.buttonTarget.addEventListener("keydown", this._onMenuButtonKeydown)
    }

    this.element.setAttribute("aria-haspopup", "true")
    document.addEventListener('keydown', this.keyboardListener)
  }

  disconnect() {
    if (this.hasButtonTarget) {
      this.buttonTarget.removeEventListener("keydown", this._onMenuButtonKeydown)
    }

    document?.removeEventListener('keydown', this.keyboardListener);
    this.activeIndex = 0;
  }

  keyboardListener(e) {
    if (!this.openValue) {
        return
    }

    if (e.key == 'Escape') {
      this.openValue = false;
    }
  }
}