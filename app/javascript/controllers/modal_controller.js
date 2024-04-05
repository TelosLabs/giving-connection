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
  }

  disconnect() {
    this.close();
  }

  open(e) {
    // disable button until modal is closed
    if (this.preventDefaultActionOpening) {
      e.preventDefault();
    }

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
  }

  close(event) {
    // Stops event bubbling if the modal was closed by a click
    if (event) event.preventDefault();

    // Unlock the scroll and restore previous scroll position
    this.unlockScroll();

    // Hide the modal
    this.containerTarget.classList.add(this.toggleClass);

    // Remove the background
    if (this.background) {
      this.background.remove();
    }
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

  closeBackground(e) {
    if (this.allowBackgroundClose && e.target === this.containerTarget) {
      this.close(e);
      this.clearUnappliedFilters();
    }
  }

  closeWithKeyboard(e) {
    if (
      e.keyCode === 27 &&
      !this.containerTarget.classList.contains(this.toggleClass)
    ) {
      this.close(e);
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
    const checkboxes = [
      ...this.containerTarget.querySelectorAll("[type='checkbox']"),
    ];

    const timeboxes = [
      ...this.containerTarget.querySelectorAll("[type='time']"),
    ];

    checkboxes.forEach((checkbox) => {
      const originalState = this.checkboxesOriginalState.shift();
      if (checkbox.checked !== originalState) checkbox.checked = originalState;
    });

    timeboxes.forEach((timebox) => {
      const originalState = this.timeboxesOriginalState.shift();
      if (timebox.value !== originalState) timebox.value = originalState;
    });
  }
}
