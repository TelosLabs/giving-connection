import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectMultiple"]

  addEmptyRequiredStyles() {
    const required = this.selectMultipleTargets.filter(select => select.querySelector("input[required=true]"))
    required.forEach(select => {
      select.classList.remove("border-blue-medium")
      select.classList.add("border-red-400")
    })
  }
}