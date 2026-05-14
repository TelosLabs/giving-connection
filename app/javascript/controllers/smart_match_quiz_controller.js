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
    // Reconcile DOM classes with actual input state. Turbo Drive snapshot
    // restoration on back/forward navigation leaves the cached HTML, but
    // input.checked may have been mutated since -- syncing here avoids the
    // "card visually still selected after deselect" race.
    this.reconcileSelectionUI()
    this.updateNextButton()
    this.bindFormGuard()
  }

  disconnect () {
    if (this.formSubmitHandler && this.hasFormTarget) {
      this.formTarget.removeEventListener('submit', this.formSubmitHandler)
    }
  }

  selectCard (event) {
    const card = event.currentTarget
    const isMultiple = card.dataset.selectMode === 'multiple'
    const input = card.querySelector('input')

    if (!input) return

    // When the click originates on the sr-only input itself (keyboard Space,
    // or a screen-reader activating the checkbox), the browser has already
    // toggled `input.checked` natively. Re-toggling here would cancel the
    // user's intent. In that case just sync the UI to the new input state.
    const originatedOnInput = event.target === input
    event.preventDefault()

    if (isMultiple) {
      if (!originatedOnInput) input.checked = !input.checked
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

  // Disable the submit button on form submit so double-clicks (and Back/Next
  // hammering while a PUT is in flight) cannot fire a second submission. The
  // button is re-enabled on the next Turbo render via connect() running again.
  bindFormGuard () {
    if (!this.hasFormTarget) return

    this.formSubmitHandler = () => {
      if (this.hasSubmitBtnTarget) {
        this.submitBtnTarget.disabled = true
        this.submitBtnTarget.setAttribute('aria-busy', 'true')
      }
    }
    this.formTarget.addEventListener('submit', this.formSubmitHandler)
  }

  reconcileSelectionUI () {
    this.element.querySelectorAll('.sm-card-option, .sm-card-option--list').forEach(card => {
      const input = card.querySelector('input')
      const checked = !!(input && input.checked)
      card.classList.toggle('selected', checked)
      const checkIcon = card.querySelector('.check-icon')
      if (checkIcon) checkIcon.classList.toggle('hidden', !checked)
    })

    this.element.querySelectorAll('.pill-label, label[data-action*="toggleCause"]').forEach(label => {
      const checkbox = label.querySelector('input[type="checkbox"]')
      const checked = !!(checkbox && checkbox.checked)
      label.classList.toggle('border-blue-medium', checked)
      label.classList.toggle('bg-blue-pale', checked)
      const checkIcon = label.querySelector('.check-icon')
      if (checkIcon) checkIcon.classList.toggle('hidden', !checked)
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
