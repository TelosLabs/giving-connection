import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "utilityInput"];
  static values = {
    inputTypes: String,
  }

  connect() {
    const initialFormInputs = [...this.formTarget.querySelectorAll(this.inputTypesValue)];
    this.formTarget.initialNumberOfInputs = this.validInputsLength(initialFormInputs);
    this.formTarget.changed = false;
    
    this.boundBeforeUnload = this.handleBeforeUnload.bind(this);
    window.addEventListener("beforeunload", this.boundBeforeUnload);
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.boundBeforeUnload);
  }

  captureUserInput(event) {
    const input = event.target;

    if (this.utilityInputTargets.includes(input) || this.eventAndInputIncompatible(event, input)) {
      return;
    }

    this.detectChanges(this.formTarget);
  }

  detectChanges(form, newInputAdded = false) {
    const didFormChange = newInputAdded || this.changesInForm(form);
    form.changed = didFormChange;
  }

  changesInForm(form) {
    const currentFormInputs = [...form.querySelectorAll(this.inputTypesValue)];

    return (this.validInputsLength(currentFormInputs) !== form.initialNumberOfInputs) ||
      currentFormInputs.some(input => this.inputValueChanged(input));
  }

  inputValueChanged(input) {
    if (input.type === "checkbox" || input.type === "radio") {
      return input.checked !== input.defaultChecked
    }

    if (input.type === "select-one") {
      const selectedOption = input.options[input.selectedIndex];
      return selectedOption.selected !== selectedOption.defaultSelected;
    }

    return input.value.trim() !== input.defaultValue;
  }

  // Some inputs don't send any data
  validInputsLength(currentFormInputs) {
    const validInputs = currentFormInputs.filter(input => {
      return !this.utilityInputTargets.includes(input);
    });

    return validInputs.length;
  }

  // `change` event is more suitable for input types that involve user selection or choice.
  eventAndInputIncompatible(event, input) {
    const inputIsSelectable =
      ["radio", "checkbox", "select-one", "select-multiple"].includes(input.type);

    return (event.type === "input" && inputIsSelectable) ||
      (event.type === "change" && !inputIsSelectable);
  }

  // users can add or remove inputs
  captureDOMUpdate(event) {
    this.detectChanges(event.currentTarget, event.detail.newInputAdded);
  }

  // Handle browser navigation (refresh, close tab, back button)
  handleBeforeUnload(event) {
    const haltController = this.application.getControllerForElementAndIdentifier(this.element, "halt-navigation-on-change");
    
    if (this.formTarget.changed && !haltController?.isSavingValue) {
      event.preventDefault();
      event.returnValue = "";
      return "";
    }
  }
}
