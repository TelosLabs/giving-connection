import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sectionElements = this.linkTargets.map(link => {
      const id = link.dataset.sectionId
      return document.getElementById(id)
    })

    this.observer = new IntersectionObserver(this.handleIntersect.bind(this), {
      root: null,
      threshold: 0,
      rootMargin: "-30% 0px -70% 0px"
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
  
    const offset = 180
    const top = section.getBoundingClientRect().top + window.scrollY - offset
  
    window.scrollTo({ top, behavior: 'smooth' })
  }
  
  
}
