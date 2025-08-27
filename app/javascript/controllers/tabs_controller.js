import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'panel']

  connect() {
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
  
  change(event) {
    event.preventDefault()
  
    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tabName
    const tabIndex = this.tabTargets.findIndex(tab => tab.dataset.tabName === tabName)
  
    if (tabIndex >= 0) {
      this.index = tabIndex
      localStorage.setItem('activeTab', tabName)
      this.updateActiveTab()
      window.dispatchEvent(new CustomEvent('tsc:tab-change'))
    }
  }
  
  updateActiveTab() {
    this.tabTargets.forEach((tab, i) => {
      if (i === this.index) {
        tab.classList.add("border-blue-medium", "text-blue-medium")
        tab.setAttribute("aria-current", "page")
      } else {
        tab.classList.remove("border-blue-medium", "text-blue-medium")
        tab.removeAttribute("aria-current")
      }
    })
  
    this.panelTargets.forEach((panel, i) => {
      if (i === this.index) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }

}