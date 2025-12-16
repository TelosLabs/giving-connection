import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "textarea"]
  static values = { max: { type: Number, default: 250 } }

  connect() {
    this.update()
  }

  update() {
    const text = this.textareaTarget.value.trim()
    const words = text.length === 0 ? [] : text.split(/\s+/)
    const wordCount = words.length

    if (wordCount > this.maxValue) {
      const limitedText = words.slice(0, this.maxValue).join(' ')
      this.textareaTarget.value = limitedText
      this.countTarget.textContent = this.maxValue
      this.countTarget.classList.add('text-red-500')
    } else {
      this.countTarget.textContent = wordCount
      
      if (wordCount >= this.maxValue - 10) {
        this.countTarget.classList.add('text-orange-500')
        this.countTarget.classList.remove('text-red-500')
      } else {
        this.countTarget.classList.remove('text-red-500', 'text-orange-500')
      }
    }
  }
}