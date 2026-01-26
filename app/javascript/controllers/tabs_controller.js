import { Controller } from '@hotwired/stimulus'

/* global localStorage */

export default class extends Controller {
  static targets = ['tab', 'panel']
  static values = {
    activeClasses: { type: String, default: 'border-blue-medium text-blue-medium' },
    hiddenClass: { type: String, default: 'hidden' }
  }

  connect () {
    // Restore active tab from localStorage or default to first tab
    const savedTabName = localStorage.getItem('activeTab')
    if (savedTabName) {
      const tabIndex = this.tabTargets.findIndex(tab => tab.dataset.tabName === savedTabName)
      this.index = tabIndex >= 0 ? tabIndex : 0 // in case no saved tab matches
    } else {
      this.index = 0
    }
    this.updateActiveTab()
  }

  change (event) {
    event.preventDefault()

    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tabName
    const tabIndex = this.tabTargets.findIndex(tab => tab.dataset.tabName === tabName)

    if (tabIndex >= 0) {
      this.index = tabIndex
      localStorage.setItem('activeTab', tabName)
      this.updateActiveTab()
      window.dispatchEvent(new CustomEvent('tsc:tab-change'))
    } else {
      console.warn(`Tab with name "${tabName}" not found`)
    }
  }

  updateActiveTab () {
    const activeClasses = this.activeClassesValue.split(' ')

    this.tabTargets.forEach((tab, i) => {
      if (i === this.index) {
        tab.classList.add(...activeClasses)
        tab.setAttribute('aria-current', 'page')
      } else {
        tab.classList.remove(...activeClasses)
        tab.removeAttribute('aria-current')
      }
    })

    this.panelTargets.forEach((panel, i) => {
      if (i === this.index) {
        panel.classList.remove(this.hiddenClassValue)
      } else {
        panel.classList.add(this.hiddenClassValue)
      }
    })
  }
}
