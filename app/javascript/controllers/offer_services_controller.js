import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "button", "form2" ]

  connect() {
  }

  toogle(event) {
    event.preventDefault()

    let content = this.formTarget.innerHTML

    if (this.buttonTarget.id == "unchecked") {

      this.buttonTarget.id = "checked"
      this.buttonTarget.insertAdjacentHTML('beforeend', content)

    } else {
      this.buttonTarget.id = "unchecked"
      this.form2Target.remove()
    }
    
  }
}
