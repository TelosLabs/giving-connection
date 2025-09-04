import { Controller } from "@hotwired/stimulus";
import Fuse from "fuse.js";

export default class extends Controller {
  static targets = ["input", "results"];

  connect() {
    this.items = Array.from(this.element.querySelectorAll('[data-controller~="toggle"]')).map((accordion, id) => {
      const trigger = accordion.querySelector('button[data-action*="toggle#toggle"]');
      const question = trigger?.querySelector("h5");
      const panel = accordion.querySelector('[data-toggle-target~="toggleable"]');
      const answer = panel?.querySelector(":scope > div");
      return { id, el: accordion, trigger, question, answer, panel };
    });

    this.docs = this.items.map(({ id, question, answer }) => ({
      id,
      title: (question?.textContent || "").trim(),
      body: (answer?.textContent || "").trim(),
    }));

    this.fuse = new Fuse(this.docs, {
      keys: [
        { name: "title", weight: 0.7 },
        { name: "body", weight: 0.3 },
      ],
      includeScore: true,
      threshold: 0.35,
      ignoreLocation: true,
      minMatchCharLength: 2,
    });

    this._renderResults([]);
  }

  onInput() {
    const query = (this.inputTarget.value || "").trim();
    if (!query) return this._renderResults([]);

    const hits = this.fuse.search(query);
    const items = hits.map(h => this.items[h.item.id]);
    this._renderResults(items);
  }

  goTo(event) {
    const id = Number(event.currentTarget.dataset.id);
    const it = this.items.find(x => x.id === id);
    if (!it) return;

    if (it.panel?.classList.contains("hidden")) it.trigger?.click();
    it.el.scrollIntoView({ behavior: "smooth", block: "start", inline: "nearest" });
  }

  _renderResults(items) {
    this.resultsTarget.innerHTML = "";
    if (!items.length) return;

    const resultDiv = document.createDocumentFragment();
    items.forEach((it) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.id = String(it.id);
      btn.className = "w-full px-3 py-2 text-left bg-white rounded-lg hover:bg-gray-7";
      btn.textContent = (it.question?.textContent || "").trim();
      btn.addEventListener("click", this.goTo.bind(this));
      resultDiv.appendChild(btn);
    });
    this.resultsTarget.appendChild(resultDiv);
  }
}
