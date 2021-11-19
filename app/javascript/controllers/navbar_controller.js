import { Controller } from "stimulus"

export default class extends Controller {
  static get targets() {
    return [ "sideNavBar" ]
  }

  openSideNavBar() {
    this.sideNavBarTarget.classList.remove('hidden')
    this.sideNavBarTarget.classList.add('sidebar-slide-in')
    this.sideNavBarTarget.classList.remove('sidebar-slide-out')
  }

  collapseSideNavBar() {
    this.sideNavBarTarget.classList.remove('sidebar-slide-in')
    this.sideNavBarTarget.classList.add('sidebar-slide-out')
    setTimeout(() => {
      this.sideNavBarTarget.classList.add('hidden')
    }, 500);
  }
}