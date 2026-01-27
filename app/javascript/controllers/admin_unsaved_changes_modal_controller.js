import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form']
  static values = {
    inputTypes: { type: String, default: 'input, select, textarea' }
  }

  connect () {
    this.hasUnsavedChanges = false
    this.initialFormState = this.captureFormState()
    this.pendingNavigationUrl = null
    this.boundHandlers = {}

    // Store bound handlers for proper cleanup
    this.boundHandlers.formChange = this.handleFormChange.bind(this)
    this.boundHandlers.formSubmit = this.handleFormSubmit.bind(this)
    this.boundHandlers.linkClick = this.handleLinkClick.bind(this)
    this.boundHandlers.popState = this.handlePopState.bind(this)
    this.boundHandlers.keyDown = this.handleKeyDown.bind(this)
    this.boundHandlers.beforeUnload = this.handleBeforeUnload.bind(this)

    // Listen for form changes
    this.formTarget.addEventListener('input', this.boundHandlers.formChange)
    this.formTarget.addEventListener('change', this.boundHandlers.formChange)

    // Listen for form submission to reset the flag
    this.formTarget.addEventListener('submit', this.boundHandlers.formSubmit)

    // Listen for link clicks and form submissions that might navigate away
    document.addEventListener('click', this.boundHandlers.linkClick)

    // Listen for popstate (back/forward button)
    window.addEventListener('popstate', this.boundHandlers.popState)

    // Listen for keyboard shortcuts that might refresh the page
    document.addEventListener('keydown', this.boundHandlers.keyDown)

    // Listen for beforeunload (page refresh/close)
    window.addEventListener('beforeunload', this.boundHandlers.beforeUnload)
  }

  disconnect () {
    // Clean up all event listeners using stored bound handlers
    if (this.boundHandlers) {
      this.formTarget.removeEventListener('input', this.boundHandlers.formChange)
      this.formTarget.removeEventListener('change', this.boundHandlers.formChange)
      this.formTarget.removeEventListener('submit', this.boundHandlers.formSubmit)
      document.removeEventListener('click', this.boundHandlers.linkClick)
      window.removeEventListener('popstate', this.boundHandlers.popState)
      window.removeEventListener('keydown', this.boundHandlers.keyDown)
      window.removeEventListener('beforeunload', this.boundHandlers.beforeUnload)
    }
  }

  handleKeyDown (event) {
    // Intercept Ctrl+R, F5, and Cmd+R (Mac) to show custom modal
    if (this.hasUnsavedChanges &&
      ((event.ctrlKey && event.key === 'r') ||
        event.key === 'F5' ||
        (event.metaKey && event.key === 'r'))) {
      event.preventDefault()
      this.pendingNavigationUrl = window.location.href // Refresh current page
      this.showModal()
    }
  }

  handleFormChange (event) {
    // Ignore utility inputs or specific input types that shouldn't trigger the warning
    if (this.shouldIgnoreInput(event.target)) {
      return
    }

    const currentFormState = this.captureFormState()
    this.hasUnsavedChanges = this.hasFormChanged(this.initialFormState, currentFormState)
  }

  handleBeforeUnload (event) {
    if (this.hasUnsavedChanges) {
      event.preventDefault()
      event.returnValue = 'You have unsaved changes. Are you sure you want to leave this page? Your changes will be lost.'
      return 'You have unsaved changes. Are you sure you want to leave this page? Your changes will be lost.'
    }
  }

  handlePopState () {
    if (this.hasUnsavedChanges) {
      // Push the current state back to prevent navigation
      window.history.pushState(null, '', window.location.href)

      this.pendingNavigationUrl = null // Will use history.back() in leavePage
      this.showModal()
    }
  }

  handleLinkClick (event) {
    const link = event.target.closest('a')
    if (link && link.closest('form') === this.formTarget) {
      return
    }
    if (link && this.hasUnsavedChanges && !this.shouldIgnoreLink(link)) {
      event.preventDefault()
      this.pendingNavigationUrl = link.href
      this.showModal()
    }
  }

  handleFormSubmit () {
    // Reset the flag when form is submitted
    this.hasUnsavedChanges = false
  }

  showModal () {
    const modalContainer = document.getElementById('unsaved-changes-modal')

    if (modalContainer) {
      modalContainer.classList.remove('hidden')
      modalContainer.classList.add('flex')
      document.body.style.overflow = 'hidden'

      // Add event listeners to the buttons
      const stayButton = modalContainer.querySelector('button:first-of-type')
      const leaveButton = modalContainer.querySelector('button:last-of-type')

      if (stayButton) {
        stayButton.addEventListener('click', this.stayOnPage.bind(this), { once: true })
      }
      if (leaveButton) {
        leaveButton.addEventListener('click', this.leavePage.bind(this), { once: true })
      }
    }
  }

  hideModal () {
    const modalContainer = document.getElementById('unsaved-changes-modal')
    if (modalContainer) {
      modalContainer.classList.add('hidden')
      modalContainer.classList.remove('flex')
      document.body.style.overflow = ''
    }
    this.pendingNavigationUrl = null
  }

  stayOnPage () {
    this.hideModal()
  }

  leavePage () {
    this.hasUnsavedChanges = false
    if (this.pendingNavigationUrl) {
      if (this.pendingNavigationUrl === window.location.href) {
        // This is a refresh request
        window.location.reload()
      } else {
        // This is navigation to a different page
        window.location.href = this.pendingNavigationUrl
      }
    } else {
      window.history.back()
    }
  }

  captureFormState () {
    const state = {}
    const inputs = this.formTarget.querySelectorAll('input, select, textarea')

    inputs.forEach(input => {
      // Skip ignored inputs
      if (this.shouldIgnoreInput(input) || !input.name) {
        return
      }

      if (input.type === 'checkbox') {
        if (!state[input.name]) {
          state[input.name] = []
        }
        if (input.checked) {
          state[input.name].push(input.value)
        }
      } else if (input.type === 'radio') {
        if (input.checked) {
          state[input.name] = input.value
        }
      } else {
        state[input.name] = input.value || ''
      }
    })

    return state
  }

  hasFormChanged (initialState, currentState) {
    // Get all unique keys from both states
    const allKeys = new Set([...Object.keys(initialState), ...Object.keys(currentState)])

    for (const key of allKeys) {
      const initialValue = initialState[key]
      const currentValue = currentState[key]

      // Handle arrays (checkboxes)
      if (Array.isArray(initialValue) || Array.isArray(currentValue)) {
        const initArray = Array.isArray(initialValue) ? initialValue : []
        const currArray = Array.isArray(currentValue) ? currentValue : []

        if (initArray.length !== currArray.length) {
          return true
        }

        // Sort and compare to handle order differences
        const sortedInit = [...initArray].sort()
        const sortedCurr = [...currArray].sort()

        for (let i = 0; i < sortedInit.length; i++) {
          if (sortedInit[i] !== sortedCurr[i]) {
            return true
          }
        }
      } else {
        // Normalize empty values
        const normalizedInit = initialValue || ''
        const normalizedCurr = currentValue || ''

        if (normalizedInit !== normalizedCurr) {
          return true
        }
      }
    }

    return false
  }

  shouldIgnoreInput (input) {
    // Ignore utility inputs, hidden inputs, or specific input types
    const ignoredTypes = ['hidden', 'submit', 'button', 'reset']
    const ignoredClasses = ['utility-input', 'ignore-unsaved-changes']

    return ignoredTypes.includes(input.type) ||
      ignoredClasses.some(className => input.classList.contains(className))
  }

  shouldIgnoreLink (link) {
    // Ignore links that shouldn't trigger the warning
    const ignoredClasses = ['ignore-unsaved-changes']
    const ignoredHrefs = ['#', 'javascript:void(0)']

    return ignoredClasses.some(className => link.classList.contains(className)) ||
      ignoredHrefs.includes(link.href) ||
      link.target === '_blank'
  }
}
