import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]
  scrolling = false

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

    this.boundScroll = this.checkBottomEntry.bind(this);
    window.addEventListener("scroll", this.boundScroll);

  }

  handleIntersect(entries) {
    const visibleEntry = entries
      .filter(entry => entry.isIntersecting)
      .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]

    if (!visibleEntry) return

    if (this.scrolling) return

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
    window.removeEventListener("scroll", this.boundScroll);
  }

  scrollToSection(event) {
    event.preventDefault()
    this.scrolling = true

    const sectionId = event.currentTarget.dataset.sectionId
    const section = document.getElementById(sectionId)
    if (!section) return
  
    const offset = 181
    const top = section.getBoundingClientRect().top + window.scrollY - offset
  
    window.scrollTo({ top, behavior: 'smooth' })
    this.linkTargets.forEach(link => {
      const isActive = link.dataset.sectionId === sectionId

      link.classList.toggle("text-blue-medium", isActive)
      link.classList.toggle("font-medium", isActive)
      link.classList.toggle("text-gray-3", !isActive)
    })

    setTimeout(() => {
      this.scrolling = false;
    }, 1000);
  
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

  toggleCollapse(event) {
    const target = event.target.closest('p');
    const list = target.nextElementSibling;
    const chevron = target.querySelector('button svg');
  
    if (list.classList.contains('hidden')) {
      list.classList.remove('hidden');
      chevron.classList.add('rotate-90');
    } else {
      list.classList.add('hidden');
      chevron.classList.remove('rotate-90');
    }
  }
  
  checkBottomEntry() {
    const el = document.getElementById("scrollable-content");
    const rect = el.getBoundingClientRect();

    console.log("Rect: ",rect.bottom)
    console.log("Height:", window.innerHeight)
  
    if (rect.bottom <= window.innerHeight + 100) {
      this.linkTargets.forEach(link => {
        const isActive = link.dataset.sectionId === "information-verification"
  
        link.classList.toggle("text-blue-medium", isActive)
        link.classList.toggle("font-medium", isActive)
        link.classList.toggle("text-gray-3", !isActive)
      })
    }
  }
  
}
