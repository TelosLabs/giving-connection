import { Controller } from "@hotwired/stimulus";
import { useDebounce } from "stimulus-use";

// Search is server-side (BlogsController#index) so the "All posts (N)"
// count and the rendered list always agree. The <form>/<input> live OUTSIDE
// the "blog-search" turbo-frame (data-turbo-frame points the submission at
// it) specifically so Turbo never replaces the input's own DOM node
export default class extends Controller {
  static targets = ["input", "form"];
  static debounces = ["submit"];

  initialize() {
    useDebounce(this, { wait: 300 });
  }

  onInput() {
    this.submit();
  }

  onKeydown(event) {
    if (event.key !== "Escape") return;

    event.preventDefault();
    this.inputTarget.value = "";
    this.inputTarget.blur();
    this.submit();
  }

  submit() {
    this.formTarget.requestSubmit();
  }
}
