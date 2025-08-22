import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];
  static values = {
    inputTypes: { type: String, default: "input, select, textarea" }
  };

  connect() {
    console.log('Admin unsaved changes modal controller connected');
    this.hasUnsavedChanges = false;
    this.initialFormState = this.captureFormState();
    this.pendingNavigationUrl = null;

    // Add initial history state to enable popstate detection
    window.history.pushState(null, '', window.location.href);

    // Listen for form changes
    this.formTarget.addEventListener('input', this.handleFormChange.bind(this));
    this.formTarget.addEventListener('change', this.handleFormChange.bind(this));

    // Listen for form submission to reset the flag
    this.formTarget.addEventListener('submit', this.handleFormSubmit.bind(this));

    // Listen for link clicks and form submissions that might navigate away
    document.addEventListener('click', this.handleLinkClick.bind(this));

    // Listen for popstate (back/forward button)
    window.addEventListener('popstate', this.handlePopState.bind(this));

    // Listen for keyboard shortcuts that might refresh the page
    document.addEventListener('keydown', this.handleKeyDown.bind(this));

    // Listen for beforeunload (page refresh/close) - fallback for browser refresh button
    window.addEventListener('beforeunload', this.handleBeforeUnload.bind(this));
  }

  disconnect() {
    document.removeEventListener('click', this.handleLinkClick.bind(this));
    window.removeEventListener('popstate', this.handlePopState.bind(this));
    document.removeEventListener('keydown', this.handleKeyDown.bind(this));
    window.removeEventListener('beforeunload', this.handleBeforeUnload.bind(this));
  }

  handleKeyDown(event) {
    console.log('Key pressed:', event.key, 'Ctrl:', event.ctrlKey, 'Meta:', event.metaKey);
    // Intercept Ctrl+R, F5, and Cmd+R (Mac) to show custom modal
    if (this.hasUnsavedChanges &&
      ((event.ctrlKey && event.key === 'r') ||
        event.key === 'F5' ||
        (event.metaKey && event.key === 'r'))) {
      console.log('Refresh shortcut detected, showing modal');
      event.preventDefault();
      this.pendingNavigationUrl = window.location.href; // Refresh current page
      this.showModal();
    }
  }

  handleFormChange(event) {
    // Ignore utility inputs or specific input types that shouldn't trigger the warning
    if (this.shouldIgnoreInput(event.target)) {
      return;
    }

    const currentFormState = this.captureFormState();
    this.hasUnsavedChanges = this.hasFormChanged(this.initialFormState, currentFormState);
    console.log('Form changed, hasUnsavedChanges:', this.hasUnsavedChanges);
  }

  handleBeforeUnload(event) {
    if (this.hasUnsavedChanges) {
      event.preventDefault();
      event.returnValue = 'You have unsaved changes. Are you sure you want to leave this page? Your changes will be lost.';
      return 'You have unsaved changes. Are you sure you want to leave this page? Your changes will be lost.';
    }
  }

  handlePopState(event) {
    console.log('Popstate event triggered, hasUnsavedChanges:', this.hasUnsavedChanges);
    console.log('Event details:', event);
    if (this.hasUnsavedChanges) {
      console.log('Preventing navigation and showing modal');
      event.preventDefault();
      this.pendingNavigationUrl = null; // Will use history.back() in leavePage
      this.showModal();

      // Push the current state back to prevent navigation
      window.history.pushState(null, '', window.location.href);
    } else {
      console.log('No unsaved changes, allowing navigation');
    }
  }

  handleLinkClick(event) {
    const link = event.target.closest('a');
    if (link && this.hasUnsavedChanges && !this.shouldIgnoreLink(link)) {
      console.log('Link click detected, showing modal');
      event.preventDefault();
      this.pendingNavigationUrl = link.href;
      this.showModal();
    }
  }

  handleFormSubmit() {
    // Reset the flag when form is submitted
    this.hasUnsavedChanges = false;
    console.log('Form submitted, resetting hasUnsavedChanges');
  }

  showModal() {
    console.log('Showing modal');
    const modalContainer = document.getElementById('unsaved-changes-modal');
    console.log('Modal container:', modalContainer);

    if (modalContainer) {
      modalContainer.classList.remove('hidden');
      modalContainer.classList.add('flex');
      document.body.style.overflow = 'hidden';

      // Add event listeners to the buttons
      const stayButton = modalContainer.querySelector('button:first-of-type');
      const leaveButton = modalContainer.querySelector('button:last-of-type');

      if (stayButton) {
        stayButton.addEventListener('click', this.stayOnPage.bind(this), { once: true });
      }
      if (leaveButton) {
        leaveButton.addEventListener('click', this.leavePage.bind(this), { once: true });
      }
    } else {
      console.error('Modal container not found!');
    }
  }

  hideModal() {
    console.log('Hiding modal');
    const modalContainer = document.getElementById('unsaved-changes-modal');
    if (modalContainer) {
      modalContainer.classList.add('hidden');
      modalContainer.classList.remove('flex');
      document.body.style.overflow = '';
    }
    this.pendingNavigationUrl = null;
  }

  stayOnPage() {
    console.log('Staying on page');
    this.hideModal();
  }

  leavePage() {
    console.log('Leaving page');
    this.hasUnsavedChanges = false;
    if (this.pendingNavigationUrl) {
      if (this.pendingNavigationUrl === window.location.href) {
        // This is a refresh request
        window.location.reload();
      } else {
        // This is navigation to a different page
        window.location.href = this.pendingNavigationUrl;
      }
    } else {
      window.history.back();
    }
  }

  captureFormState() {
    const formData = new FormData(this.formTarget);
    const state = {};

    for (let [key, value] of formData.entries()) {
      if (state[key]) {
        // Handle multiple values (like checkboxes)
        if (Array.isArray(state[key])) {
          state[key].push(value);
        } else {
          state[key] = [state[key], value];
        }
      } else {
        state[key] = value;
      }
    }

    return state;
  }

  hasFormChanged(initialState, currentState) {
    const initialKeys = Object.keys(initialState);
    const currentKeys = Object.keys(currentState);

    // Check if any keys were added or removed
    if (initialKeys.length !== currentKeys.length) {
      return true;
    }

    // Check if any values changed
    for (let key of initialKeys) {
      if (!currentState.hasOwnProperty(key)) {
        return true;
      }

      const initialValue = initialState[key];
      const currentValue = currentState[key];

      if (Array.isArray(initialValue) && Array.isArray(currentValue)) {
        if (initialValue.length !== currentValue.length) {
          return true;
        }
        for (let i = 0; i < initialValue.length; i++) {
          if (initialValue[i] !== currentValue[i]) {
            return true;
          }
        }
      } else if (initialValue !== currentValue) {
        return true;
      }
    }

    return false;
  }

  shouldIgnoreInput(input) {
    // Ignore utility inputs, hidden inputs, or specific input types
    const ignoredTypes = ['hidden', 'submit', 'button', 'reset'];
    const ignoredClasses = ['utility-input', 'ignore-unsaved-changes'];

    return ignoredTypes.includes(input.type) ||
      ignoredClasses.some(className => input.classList.contains(className));
  }

  shouldIgnoreLink(link) {
    // Ignore links that shouldn't trigger the warning
    const ignoredClasses = ['ignore-unsaved-changes'];
    const ignoredHrefs = ['#', 'javascript:void(0)'];

    return ignoredClasses.some(className => link.classList.contains(className)) ||
      ignoredHrefs.includes(link.href) ||
      link.target === '_blank';
  }
}
