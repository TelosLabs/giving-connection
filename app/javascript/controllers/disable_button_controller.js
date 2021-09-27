import { Controller } from "@hotwired/stimulus"
// import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    console.log("Hello from your first Stimulus controller")
  }
}