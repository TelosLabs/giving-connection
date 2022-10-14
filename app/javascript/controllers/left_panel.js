import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  closeLocationPanel(event) {
    console.log(event);
    let container = document.getElementById('left-side-panel')
    container.childNodes.forEach((node) => {
      node.classList.add('hidden')
    })
  }
}
