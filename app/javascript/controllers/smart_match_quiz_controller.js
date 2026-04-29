import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'form',
    'radio',
    'submitBtn',
    'causeCheckbox',
    'accordion',
    'accordionIcon',
    'accordionContent'
  ]

  static values = {
    step: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 4 }
  }

  connect () {
    this.updateNextButton()
  }

  selectCard (event) {
    event.preventDefault()
    const card = event.currentTarget
    const isMultiple = card.dataset.selectMode === 'multiple'
    const input = card.querySelector('input')

    if (!input) return

    if (isMultiple) {
      input.checked = !input.checked
      card.classList.toggle('selected', input.checked)

      const checkIcon = card.querySelector('.check-icon')
      if (checkIcon) checkIcon.classList.toggle('hidden', !input.checked)

      this.syncMirrorCards(input.value, input.checked)
    } else {
      this.deselectSiblingCards(card)
      input.checked = true
      card.classList.add('selected')
    }

    this.updateNextButton()
  }

  toggleCause (event) {
    event.preventDefault()
    const label = event.currentTarget
    const checkbox = label.querySelector('input[type="checkbox"]')

    if (!checkbox) return

    checkbox.checked = !checkbox.checked
    label.classList.toggle('border-blue-medium', checkbox.checked)
    label.classList.toggle('bg-blue-pale', checkbox.checked)

    const checkIcon = label.querySelector('.check-icon')
    if (checkIcon) checkIcon.classList.toggle('hidden', !checkbox.checked)

    this.updateNextButton()
  }

  selectOption (event) {
    const label = event.currentTarget
    this.element.querySelectorAll('.pill-label, label[data-action*="selectOption"]').forEach(el => {
      el.classList.remove('border-blue-medium', 'bg-blue-pale')
    })
    label.classList.add('border-blue-medium', 'bg-blue-pale')

    this.updateNextButton()
  }

  toggleAccordion () {
    if (!this.hasAccordionContentTarget) return

    const content = this.accordionContentTarget
    const isOpen = content.classList.contains('open')

    content.classList.toggle('open', !isOpen)

    if (this.hasAccordionIconTarget) {
      this.accordionIconTarget.style.transform = isOpen ? '' : 'rotate(180deg)'
    }
  }

  updateNextButton () {
    if (!this.hasSubmitBtnTarget) return

    const hasSelection = this.hasAnySelection()
    this.submitBtnTarget.disabled = !hasSelection
  }

  // private

  deselectSiblingCards (card) {
    const group = card.closest('[data-card-group]')
    if (!group) return

    group.querySelectorAll('.sm-card-option, .sm-card-option--list').forEach(c => {
      c.classList.remove('selected')
      const input = c.querySelector('input')
      if (input) input.checked = false
      const checkIcon = c.querySelector('.check-icon')
      if (checkIcon) checkIcon.classList.add('hidden')
    })
  }

  syncMirrorCards (value, checked) {
    this.element.querySelectorAll(`input[value="${value}"]`).forEach(input => {
      input.checked = checked
      const card = input.closest('.sm-card-option, .sm-card-option--list')
      if (card) {
        card.classList.toggle('selected', checked)
        const checkIcon = card.querySelector('.check-icon')
        if (checkIcon) checkIcon.classList.toggle('hidden', !checked)
      }
    })
  }

  hasAnySelection () {
    const radios = this.element.querySelectorAll('input[type="radio"]')
    if (radios.length > 0) {
      return Array.from(radios).some(r => r.checked)
    }

    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    if (checkboxes.length > 0) {
      return Array.from(checkboxes).some(c => c.checked)
    }

    const selects = this.element.querySelectorAll('select')
    if (selects.length > 0) {
      return Array.from(selects).every(s => s.value !== '')
    }

    const textareas = this.element.querySelectorAll('textarea')
    if (textareas.length > 0) {
      return Array.from(textareas).some(t => t.value.trim() !== '')
    }

    return false
  }
}
