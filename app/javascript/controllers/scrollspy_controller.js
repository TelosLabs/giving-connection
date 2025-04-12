import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sectionElements = this.linkTargets.map(link => {
      const id = link.dataset.sectionId
      return document.getElementById(id)
    })

    this.addDynamicLocationLinks()

    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      root: null,
      threshold: 0,
      rootMargin: `-${181 + 20}px 0px -70% 0px`
    })

    this.sectionElements.forEach(section => {
      if (section) this.observer.observe(section)
    })
  }

  handleIntersect(entries) {
    const visibleEntry = entries
      .filter(entry => entry.isIntersecting)
      .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]

    if (!visibleEntry) return

    const visibleId = visibleEntry.target.id

    this.linkTargets.forEach(link => {
      const isActive = link.dataset.sectionId === visibleId

      link.classList.toggle("text-blue-medium", isActive)
      link.classList.toggle("font-medium", isActive)
      link.classList.toggle("text-gray-3", !isActive)
    })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  scrollToSection(event) {
    event.preventDefault()
  
    const sectionId = event.currentTarget.dataset.sectionId
    const section = document.getElementById(sectionId)
    if (!section) return
  
    const offset = 181
    const top = section.getBoundingClientRect().top + window.scrollY - offset
  
    window.scrollTo({ top, behavior: 'smooth' })
  }

  scrollToTop(event) {
    event.preventDefault()
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  addDynamicLocationLinks() {
    const sidebarContainer = document.getElementById('sidebar-add-locations')
    const dynamicLocations = document.querySelectorAll('[id^="add-location-"]')
  
    dynamicLocations.forEach(location => {
      const label = location.dataset.label || "Unnamed Location"
      const id = location.id
  
      const link = document.createElement('p')
      link.setAttribute('role', 'button')
      link.setAttribute('data-section-id', id)
      link.setAttribute('data-scrollspy-target', 'link')
      link.setAttribute('data-action', 'click->scrollspy#scrollToSection')
      link.className = "flex items-center p-1 text-lg font-light leading-7 transition rounded-md cursor-pointer text-gray-3 hover:text-blue-medium hover:bg-blue-100"
  
      link.innerHTML = `<svg class="w-4 h-4 mr-1"><use xlink:href="#location-dot"></use></svg> ${label}`
  
      sidebarContainer.appendChild(link)
  
      this.sectionElements.push(location)
    })
  }
  
}
