import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["links", "template"]

  connect() {
    this.wrapperClass = this.data.get("wrapperClass") || "nested-fields"
  }

  add_association(event) {
    event.preventDefault()

    var content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.linksTarget.insertAdjacentHTML('beforebegin', content)
    this.dispatch("domupdate", { detail: { newInputAdded: true } })
  }

  remove_association(event) {
    event.preventDefault()

    let wrapper = event.target.closest("." + this.wrapperClass)
    // New records are simply removed from the page
    if (wrapper.dataset.newRecord == "true") {
      wrapper.remove()
      this.dispatch("domupdate")
    }
    // Existing records are hidden and flagged for deletion
    else {
      const deletionFlag = wrapper.querySelector("input[name*='_destroy']")
      const inputEvent = new Event("input", { bubbles: true })

      deletionFlag.value = 1
      deletionFlag.dispatchEvent(inputEvent)
      wrapper.style.display = 'none'
    }
  }
}
