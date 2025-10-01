import { Controller } from "@hotwired/stimulus";
import { useDebounce } from "stimulus-use";
import Fuse from "fuse.js";

/**
 * FAQ Search Controller
 *
 * Provides fuzzy search functionality for FAQ accordion items and quick links.
 * Uses Fuse.js for search and stimulus-use for debouncing.
 *
 * Targets:
 * - input: The search input field
 * - results: Container for search results
 */
export default class extends Controller {
  static targets = ["input", "results"];
  static debounces = ["performSearch"];

  // Lifecycle Methods
  // ================

  initialize() {
    // Store event listeners and timeouts for cleanup
    this.eventListeners = [];
    this.highlightTimeouts = [];

    // Initialize debounce with 300ms delay
    useDebounce(this, { wait: 300 });
  }

  connect() {
    try {
      this.initializeSearchData();
      this.initializeFuseSearch();
      this.renderResults([]);
    } catch (error) {
      this.handleInitializationError(error);
    }
  }

  disconnect() {
    this.cleanupEventListeners();
    this.clearHighlightTimeouts();
    this.clearSearchResults();
    this.resetSearchData();
  }

  // Public Action Methods
  // ====================

  /**
   * Action method called from HTML template (input->faq-search#onInput)
   */
  onInput() {
    this.handleInput();
  }

  /**
   * Action method called from HTML template (keydown->faq-search#onKeydown)
   */
  onKeydown(event) {
    this.handleKeydown(event);
  }

  /**
   * Handles input events from the search field
   */
  handleInput() {
    const query = (this.inputTarget.value || "").trim();

    // Immediately clear results if input is empty (no debounce delay)
    if (!query) {
      this.renderResults([]);
      return;
    }

    // Call debounced search method for actual searches
    this.performSearch();
  }

  /**
   * Handles keyboard navigation in search results
   */
  handleKeydown(event) {
    if (!this.hasResultsTarget) return;

    const results = this.resultsTarget.querySelectorAll('button');
    if (results.length === 0) return;

    const currentFocus = document.activeElement;
    let currentIndex = Array.from(results).indexOf(currentFocus);

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (currentIndex < results.length - 1) {
          results[currentIndex + 1].focus();
        } else if (currentIndex === -1) {
          results[0].focus();
        }
        break;

      case 'ArrowUp':
        event.preventDefault();
        if (currentIndex > 0) {
          results[currentIndex - 1].focus();
        } else if (currentIndex === 0) {
          this.inputTarget.focus();
        }
        break;

      case 'Enter':
        if (currentIndex >= 0) {
          event.preventDefault();
          results[currentIndex].click();
        }
        break;

      case 'Escape':
        event.preventDefault();
        this.renderResults([]);
        this.inputTarget.focus();
        break;
    }
  }

  /**
   * Debounced search method (configured in static debounces)
   */
  performSearch() {
    try {
      const query = (this.inputTarget.value || "").trim();
      if (!query) return this.renderResults([]);

      // Check if Fuse is initialized
      if (!this.fuse) {
        console.warn("Search not available - no searchable content found");
        return this.renderResults([]);
      }

      const hits = this.fuse.search(query);
      const items = hits.map(h => this.items[h.item.id]).filter(Boolean);
      this.renderResults(items);
    } catch (error) {
      console.error("Search failed:", error);
      this.renderResults([]);
    }
  }

  /**
   * Handles navigation to search result items
   */
  navigateToItem(event) {
    try {
      const id = Number(event.currentTarget.dataset.id);
      const item = this.items.find(x => x.id === id);
      if (!item) return;

      if (item.type === "quick") {
        this.navigateToQuickLink(item);
      } else {
        this.navigateToAccordion(item);
      }
    } catch (error) {
      console.error("Navigation failed:", error);
    }
  }

  // Private Initialization Methods
  // =============================

  initializeSearchData() {
    this.items = [];
    this.processAccordionItems();
    this.processQuickLinks();
    this.assignItemIds();
    this.createSearchableDocuments();
  }

  processAccordionItems() {
    const accordionSection = this.element.querySelectorAll('[data-controller~="toggle"]');
    if (accordionSection.length > 0) {
      const accordionItems = Array.from(accordionSection).map((accordion) => {
        const trigger = accordion.querySelector('button[data-action*="toggle#toggle"]');
        const question = trigger?.querySelector("h5");
        const panel = accordion.querySelector('[data-toggle-target~="toggleable"]');
        const answer = panel?.querySelector(":scope > div");
        return { type: "accordion", el: accordion, trigger, question, answer, panel };
      });
      this.items.push(...accordionItems);
    }
  }

  processQuickLinks() {
    const quickLinksSection = this.element.querySelector("#quick-links");
    if (quickLinksSection) {
      const quickLinksItems = quickLinksSection.querySelectorAll("ul li");
      if (quickLinksItems.length > 0) {
        const quickItems = Array.from(quickLinksItems).map((li) => {
          const anchor = li.querySelector("a");
          const title = (anchor?.textContent || "").trim().replace(/[:：]\s*$/, "");
          const body = (li.textContent || "").trim();
          const href = anchor?.getAttribute("href") || null;
          return { type: "quick", el: li, section: quickLinksSection, anchor, title, body, href };
        });
        this.items.push(...quickItems);
      }
    }
  }

  assignItemIds() {
    this.items.forEach((item, id) => (item.id = id));
  }

  createSearchableDocuments() {
    this.docs = this.items.map((item) => {
      if (item.type === "quick") {
        return { id: item.id, type: item.type, title: item.title, body: item.body };
      }
      return {
        id: item.id,
        type: item.type,
        title: (item.question?.textContent || "").trim(),
        body: (item.answer?.textContent || "").trim()
      };
    });
  }

  initializeFuseSearch() {
    if (this.docs.length > 0) {
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
    }
  }

  handleInitializationError(error) {
    console.error("FAQ Search Controller initialization failed:", error);
    if (this.hasInputTarget) {
      this.inputTarget.disabled = true;
      this.inputTarget.placeholder = "Search temporarily unavailable";
    }
  }

  // Private Navigation Methods
  // =========================

  navigateToQuickLink(item) {
    item.section?.scrollIntoView({ behavior: "smooth", block: "center" });
    if (item.anchor) {
      item.anchor.focus({ preventScroll: true });
      this.highlightElement(item.anchor);
    }
  }

  navigateToAccordion(item) {
    if (item.panel?.classList.contains("hidden")) {
      item.trigger?.click();
    }

    // Use a slight delay to ensure accordion is fully expanded before scrolling
    setTimeout(() => {
      item.el.scrollIntoView({
        behavior: "smooth",
        block: "center",
        inline: "nearest"
      });
    }, 100);
  }

  highlightElement(element) {
    element.classList.add("ring-2", "ring-offset-2", "text-lg", "font-bold", "transition-all");

    const timeout = setTimeout(() => {
      element.classList.remove("ring-2", "ring-offset-2", "text-lg", "font-bold");
    }, 3000);

    this.highlightTimeouts.push(timeout);
  }

  // Private Rendering Methods
  // ========================

  renderResults(items) {
    this.clearSearchResults();
    if (!items.length) return;

    const resultDiv = document.createDocumentFragment();
    items.forEach((item) => {
      const button = this.createResultButton(item);
      resultDiv.appendChild(button);
    });

    if (this.hasResultsTarget) {
      this.resultsTarget.appendChild(resultDiv);
    }
  }

  createResultButton(item) {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.id = String(item.id);
    button.className = "w-full px-3 py-2 text-left bg-white rounded-lg hover:bg-gray-7";

    const label = item.type === "quick"
      ? item.title
      : (item.question?.textContent || "").trim();
    button.textContent = label;

    const clickHandler = this.navigateToItem.bind(this);
    button.addEventListener("click", clickHandler);

    this.eventListeners.push({
      element: button,
      event: "click",
      handler: clickHandler
    });

    return button;
  }

  // Private Cleanup Methods
  // ======================

  cleanupEventListeners() {
    this.eventListeners.forEach(({ element, event, handler }) => {
      element.removeEventListener(event, handler);
    });
    this.eventListeners = [];
  }

  clearHighlightTimeouts() {
    this.highlightTimeouts.forEach(timeout => clearTimeout(timeout));
    this.highlightTimeouts = [];
  }

  clearSearchResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = "";
    }
  }

  resetSearchData() {
    this.fuse = null;
    this.items = [];
    this.docs = [];
  }
}
