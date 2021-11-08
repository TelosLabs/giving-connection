import { Controller } from "stimulus"

export default class extends Controller {
  static get targets() {
    return [ "sideNavBar" ]
  }

  openSideNavBar() {
    this.sideNavBarTarget.classList.toggle('hidden')
  }

  collapseSideNavBar() {
    this.sideNavBarTarget.classList.add('hidden')
  }
}