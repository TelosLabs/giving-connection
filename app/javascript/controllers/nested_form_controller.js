import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "links", "template" ]

  connect() {
    this.wrapperClass = this.data.get("wrapperClass") || "nested-fields"
    console.log(this.wrapperClass)
  }

  add_association(event) {
    event.preventDefault()
    // console.log(this.templateTarget)
    console.log(this.linksTarget)

    var content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.linksTarget.insertAdjacentHTML('beforebegin', content)
  }

  remove_association(event) {
    event.preventDefault()

    let wrapper = event.target.closest("." + this.wrapperClass)
    console.log(wrapper)
    console.log(wrapper.querySelector("#remove_location"))
    // New records are simply removed from the page
    if (wrapper.dataset.newRecord == "true") {
      wrapper.remove()

    // Existing records are hidden and flagged for deletion
    } else {
      wrapper.querySelector("#remove_location").value = 1
      wrapper.style.display = 'none'
    }
  }
}