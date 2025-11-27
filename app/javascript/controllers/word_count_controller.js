import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "textarea"]

  connect() {
    this.update()
  }

  update() {
    const text = this.textareaTarget.value.trim()
    const wordCount = text.length === 0 ? 0 : text.split(/\s+/).length
    this.countTarget.textContent = wordCount
  }
}