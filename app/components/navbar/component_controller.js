import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "sideNavBar" ]
  }

  openSideNavBar() {
    this.sideNavBarTarget.classList.remove('hidden')
    this.sideNavBarTarget.classList.add('sidebar-slide-in')
    this.sideNavBarTarget.classList.remove('sidebar-slide-out')
    document.body.classList.add('overflow-hidden')
  }

  collapseSideNavBar() {
    this.sideNavBarTarget.classList.remove('sidebar-slide-in')
    this.sideNavBarTarget.classList.add('sidebar-slide-out')
    document.body.classList.remove('overflow-hidden')
    setTimeout(() => {
      this.sideNavBarTarget.classList.add('hidden')
    }, 500);
  }
}
