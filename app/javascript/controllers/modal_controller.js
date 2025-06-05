import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  static targets = ["container"];
  static values = {
    backdropColor: { type: String, default: "rgba(0, 0, 0, 0.8)" },
    restoreScroll: { type: Boolean, default: true },
  };

  connect() {
    // The class we should toggle on the container
    this.toggleClass = this.data.get("class") || "hidden";

    // The ID of the background to hide/remove
    this.backgroundId = this.data.get("backgroundId") || "modal-background";

    // The HTML for the background element
    this.backgroundHtml =
      this.data.get("backgroundHtml") || this._backgroundHTML();

    // Let the user close the modal by clicking on the background
    this.allowBackgroundClose =
      (this.data.get("allowBackgroundClose") || "true") === "true";

    // Prevent the default action of the clicked element (following a link for example) when opening the modal
    this.preventDefaultActionOpening =
      (this.data.get("preventDefaultActionOpening") || "true") === "true";

    // Prevent the default action of the clicked element (following a link for example) when closing the modal
    this.preventDefaultActionClosing =
      (this.data.get("preventDefaultActionClosing") || "true") === "true";

    this.appliedIcon = document.querySelector("#appliedIcon");
    this.modalCheckboxes = Array.from(
      document.querySelectorAll("input.modal-checkbox")
    );
    this.displayAppliedIcon();

    this.skipUnsavedCheck = false;

    this.boundActuallyCloseModal = this._actuallyCloseModal.bind(this);
    document.addEventListener("turbo:submit-end", this.boundActuallyCloseModal);
  }

  disconnect() {
    this.skipUnsavedCheck = true;
    this._actuallyCloseModal();
    this.close();
    document.removeEventListener("turbo:submit-end", this.boundActuallyCloseModal);
  }

  open(e) {
    // disable button until modal is closed
    if (this.preventDefaultActionOpening) {
      e.preventDefault();
    }

    if (!this.containerTarget || !this.containerTarget.classList) {
      console.warn("Modal container not ready. Aborting open().");
      return;
    }
x
    if (e.target.blur) {
      e.target.blur();
    }

    // Lock the scroll and save current scroll position
    this.lockScroll();

    // Unhide the modal
    this.containerTarget.classList.remove(this.toggleClass);

    // Insert the background
    if (!this.data.get("disable-backdrop")) {
      document.body.insertAdjacentHTML("beforeend", this.backgroundHtml);
      this.background = document.querySelector(`#${this.backgroundId}`);
    }

    this.readCheckboxesState();
  }

  close(event, options = {}) {
    if (event) event.preventDefault();
  
    const skipUnsaved = options.skipUnsaved || false;
  
    if (!this.skipUnsavedCheck && !skipUnsaved && this.hasUnsavedChanges()) {
      this.triggerUnsavedChangesModal();
      return;
    }
  
    this._actuallyCloseModal();
    this.skipUnsavedCheck = false;
  }
  

  clearUnappliedFilters() {
    // gets the query string of the url
    const queryString = window.location.href.split("?")[1];
    // produces an array of values of the key/value pairs from the query string
    const values = [...new URLSearchParams(queryString).values()];

    // validates if all checked filters are applied (present in the query string of the url)
    this.containerTarget.querySelectorAll("input:checked").forEach((filter) => {
      if (!values.includes(filter.value)) {
        // fires data-action that unchecks and removes displayed badges
        filter.click();
      }
    });
  }

  closeBackground(event) {
    if (this.allowBackgroundClose && event.target === this.containerTarget) {
      this.close(event);
      this.clearUnappliedFilters();
    }
  }  
  
  closeWithKeyboard(event) {
    if (
      event.keyCode === 27 &&
      !this.containerTarget.classList.contains(this.toggleClass)
    ) {
      this.close(event);
    }
  }  

  _backgroundHTML() {
    return `<div id="${this.backgroundId}" class="fixed top-0 left-0 w-full h-full" style="background-color: ${this.backdropColorValue}; z-index: 9998;"></div>`;
  }

  lockScroll() {
    // Add right padding to the body so the page doesn't shift
    // when we disable scrolling
    const scrollbarWidth =
      window.innerWidth - document.documentElement.clientWidth;
    document.body.style.paddingRight = `${scrollbarWidth}px`;

    // Add classes to body to fix its position
    document.body.classList.add("fixed", "inset-x-0", "overflow-hidden");

    if (this.restoreScrollValue) {
      // Save the scroll position
      this.saveScrollPosition();

      // Add negative top position in order for body to stay in place
      document.body.style.top = `-${this.scrollPosition}px`;
    }
  }

  unlockScroll() {
    // Remove tweaks for scrollbar
    document.body.style.paddingRight = null;

    // Remove classes from body to unfix position
    document.body.classList.remove("fixed", "inset-x-0", "overflow-hidden");

    // Restore the scroll position of the body before it got locked
    if (this.restoreScrollValue) {
      this.restoreScrollPosition();

      // Remove the negative top inline style from body
      document.body.style.top = null;
    }
  }

  saveScrollPosition() {
    this.scrollPosition = window.pageYOffset || document.body.scrollTop;
  }

  restoreScrollPosition() {
    if (this.scrollPosition === undefined) return;

    document.documentElement.scrollTop = this.scrollPosition;
  }

  displayAppliedIcon() {
    if (this.appliedIcon === null) { return }

    if (this.modalCheckboxes.some((check) => check.checked === true)) {
      this.appliedIcon.classList.remove("hidden");
      this.appliedIcon.classList.add("inline-block");
    } else {
      this.appliedIcon.classList.add("hidden");
      this.appliedIcon.classList.remove("inline-block");
    }
  }

  /* For checkboxes in modal */

  readCheckboxesState() {
    const checkboxes = [
      ...this.containerTarget.querySelectorAll("[type='checkbox']"),
    ];

    this.checkboxesOriginalState = checkboxes.map(
      (checkbox) => checkbox.checked
    );

    const timeboxes = [
      ...this.containerTarget.querySelectorAll("[type='time']"),
    ];

    this.timeboxesOriginalState = timeboxes.map(
      (timebox) => timebox.value
    );
  }

  restoreCheckboxesState() {
    console.log("Restoring checkboxes state");
    const checkboxes = [
      ...this.containerTarget.querySelectorAll("[type='checkbox']"),
    ];
  
    const timeboxes = [
      ...this.containerTarget.querySelectorAll("[type='time']"),
    ];
  
    checkboxes.forEach((checkbox, index) => {
      const originalState = this.checkboxesOriginalState?.[index];
      if (originalState !== undefined && checkbox.checked !== originalState) {
        checkbox.checked = originalState;
      }
    });
  
    timeboxes.forEach((timebox, index) => {
      const originalState = this.timeboxesOriginalState?.[index];
      if (originalState !== undefined && timebox.value !== originalState) {
        timebox.value = originalState;
      }
    });
  }  

  hasUnsavedChanges() {
    const checkboxes = [
      ...this.containerTarget.querySelectorAll("[type='checkbox']"),
    ];
    const timeboxes = [
      ...this.containerTarget.querySelectorAll("[type='time']"),
    ];
  
    const currentCheckboxes = checkboxes.map((checkbox) => checkbox.checked);
    const currentTimeboxes = timeboxes.map((timebox) => timebox.value);
  
    return (
      JSON.stringify(currentCheckboxes) !== JSON.stringify(this.checkboxesOriginalState) ||
      JSON.stringify(currentTimeboxes) !== JSON.stringify(this.timeboxesOriginalState)
    );
  }

  triggerUnsavedChangesModal() {
    const event = new CustomEvent("show-unsaved-modal", {
      bubbles: true,
      detail: { url: "javascript:void(0)" }
    });
  
    this.element.dispatchEvent(event);
  }

  _actuallyCloseModal() {
    this.unlockScroll();
    this.containerTarget.classList.add(this.toggleClass);
    if (this.background) this.background.remove();
  }

  
  submitAndClose(event) {
    this.skipUnsavedCheck = true;
    this.readCheckboxesState();
    this._actuallyCloseModal();
  }

  leave(event) {
    event.preventDefault();
  
    const targetHref = event.currentTarget.getAttribute("href");
  
    this.skipUnsavedCheck = true;
    this.close();
  
    document.querySelectorAll('[data-controller~="modal"]').forEach((el) => {
      if (el === this.element) return;
  
      const modalController = this.application.getControllerForElementAndIdentifier(el, "modal");
  
      if (modalController) {
        modalController.restoreCheckboxesState();
        modalController.skipUnsavedCheck = true;
        modalController.close();
      }
    });
  
    setTimeout(() => {
      if (targetHref && targetHref !== "javascript:void(0)") {
        window.location.href = targetHref;
      }
    }, 100);
  }  
  
}
