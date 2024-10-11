import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["generalPopulationCheckbox", "specificPopulationsContainer"];
  static classes = ["disabled"]; // Only for user's organization form

  connect() {
    if (this.hasDisabledClass) {
      this.clearSelectedPopulations();
    }
    else {
      this.clearSelectedPopulationsAdminPanel();
    }
  }

  clearSelectedPopulations() {
    if (this.generalPopulationCheckboxTarget.checked) {
      const selectedPopulations = this.populations.filter(population => population.checked);
      const clickEvent = new Event("click"); // So they will be unselected as usual

      selectedPopulations.forEach(population => {
        population.checked = false;
        population.dispatchEvent(clickEvent);
      });

      this.specificPopulationsContainerTarget.classList.add(this.disabledClass);
    }
    else {
      this.specificPopulationsContainerTarget.classList.remove(this.disabledClass);
    }
  }

  clearSelectedPopulationsAdminPanel() {
    if (this.generalPopulationCheckboxTarget.checked) {
      const selectedPopulations = this.populations.filter(population => population.checked);
      selectedPopulations.forEach(input => input.checked = false);
      this.populations.forEach(input => input.setAttribute("disabled", true));
    }
    else {
      this.populations.forEach(input => input.removeAttribute("disabled"));
    }
  }

  get populations() {
    return [...this.specificPopulationsContainerTarget.querySelectorAll("input[type='checkbox']")];
  }
}
