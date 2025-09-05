import { Controller } from "@hotwired/stimulus";
import Fuse from "fuse.js";

export default class extends Controller {
  static targets = ["input", "results"];

  connect() {
    const accordionSection = this.element.querySelectorAll('[data-controller~="toggle"]');
    const accordionItems = Array.from(accordionSection).map((accordion) => {
      const trigger = accordion.querySelector('button[data-action*="toggle#toggle"]');
      const question = trigger?.querySelector("h5");
      const panel = accordion.querySelector('[data-toggle-target~="toggleable"]');
      const answer = panel?.querySelector(":scope > div");
      return { type: "accordion", el: accordion, trigger, question, answer, panel };
    });

    const quickLinksSection = this.element.querySelector("#quick-links");
    const quickItems = Array.from(quickLinksSection.querySelectorAll("ul li")).map((li) => {
      const anchor = li.querySelector("a");
      const title = (anchor?.textContent || "").trim().replace(/[:：]\s*$/, "");
      const body = (li.textContent || "").trim();
      const href = anchor?.getAttribute("href") || null;
      return { type: "quick", el: li, section: quickLinksSection, anchor, title, body, href };
    });

    this.items = [...accordionItems, ...quickItems];
    this.items.forEach((it, id) => (it.id = id));

    this.docs = this.items.map((it) => {
      if (it.type === "quick") {
        return { id: it.id, type: it.type, title: it.title, body: it.body };
      }
      return { id: it.id, type: it.type, title: (it.question?.textContent || "").trim(), body: (it.answer?.textContent || "").trim() };
    });

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

  goTo = (event) => {
    const id = Number(event.currentTarget.dataset.id);
    const it = this.items.find(x => x.id === id);
    if (!it) return;

    if (it.type === "quick") {
      it.section?.scrollIntoView({ behavior: "smooth", block: "start" });
      if (it.anchor) {
        it.anchor.focus({ preventScroll: true });
        it.anchor.classList.add("ring-2", "ring-offset-2", "text-lg", "font-bold", "transition-all");
        setTimeout(() => { it.anchor.classList.remove("ring-2", "ring-offset-2", "text-lg", "font-bold") }, 3000);
      }
      return;
    }

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
      const label = it.type === "quick" ? it.title : (it.question?.textContent || "").trim();
      btn.className = "w-full px-3 py-2 text-left bg-white rounded-lg hover:bg-gray-7";
      btn.textContent = label;
      btn.addEventListener("click", this.goTo);
      resultDiv.appendChild(btn);
    });
    this.resultsTarget.appendChild(resultDiv);
  }
}
