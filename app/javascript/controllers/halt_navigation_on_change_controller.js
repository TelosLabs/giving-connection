import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "modalTemplate"]
  static values = {
    modalContainerId: String,
    discardOptionId: String,
    isSaving: Boolean 
  }

  connect() {
    this.isSavingValue = false
  }

  // click-based
  displayModalOnChange(event) {
    if (this.isSavingValue) {
      return;
    } else if (this.formTarget.changed && !this.isSavingValue) {
      event.preventDefault();
      const modal = this.modal;
      this.prepareDiscardOption(modal, event.detail.url);
      this.addModalToDocument(modal);
    }
  }

  // Modal is added out of this controller scope
  prepareDiscardOption(modal, targetLocation) {
    const discardOption = modal.querySelector(`#${this.discardOptionIdValue}`);
    discardOption.setAttribute("href", targetLocation);
  }

  addModalToDocument(modal) {
    const modalContainer = document.getElementById(this.modalContainerIdValue);
    modalContainer.appendChild(modal);
  }

  get modal() {
    const modalFragment = this.modalTemplateTarget.content;
    return document.importNode(modalFragment, true);
  }

  startSaving() {
    this.isSavingValue = true;
  }
}
