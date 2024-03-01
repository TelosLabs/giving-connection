import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "list"];

  connect() {
    console.log("Autocomplete controller connected")
    this.inputTarget.addEventListener("input", this.search.bind(this));
  }

  async search() {
      const query = this.inputTarget.value;

      if (query.length < 2) {
        this.listTarget.innerHTML = "";
        return;
      }

      const response = await fetch(`/autocomplete?query=${query}`);
      const data = await response.json();

      console.log(data)
      this.renderList(data);
  }

  renderList(data) {
    this.listTarget.innerHTML = "";
    data.forEach(item => {
      const listItem = document.createElement("li");
      listItem.textContent = item;
      this.listTarget.appendChild(listItem);
    });
  }
}
