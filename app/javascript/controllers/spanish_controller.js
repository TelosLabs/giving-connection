import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "form", "button", "form2" ]

  connect() {
    console.log(this.formTarget)
    console.log(this.buttonTarget.id)
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
