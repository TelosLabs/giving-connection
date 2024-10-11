import { Controller } from  "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "popover", "content", "card" ]

  show() {
    const templateContent = this.contentTarget.content
    let content = document.importNode(templateContent, true)
    this.popoverTarget.appendChild(content)
  }

  hide(){
    this.cardTargets.forEach(card => {
      card.remove()
    })
  }
}