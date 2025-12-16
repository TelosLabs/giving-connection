import { Controller } from "@hotwired/stimulus";
import { useDebounce } from "stimulus-use";
import Fuse from "fuse.js";

export default class extends Controller {
  static targets = ["input", "blogItem"];
  static debounces = ["performSearch"];

  initialize() {
    useDebounce(this, { wait: 300 });
  }

  connect() {
    this.initializeSearchData();
    this.initializeFuseSearch();
  }

  disconnect() {
    this.fuse = null;
    this.blogs = [];
  }

  onInput() {
    const query = (this.inputTarget.value || "").trim();

    if (!query) {
      this.showAllBlogs();
      return;
    }

    this.performSearch();
  }

  onKeydown(event) {
    if (event.key === 'Escape') {
      event.preventDefault();
      this.inputTarget.value = '';
      this.showAllBlogs();
      this.inputTarget.blur();
    }
  }

  performSearch() {
    const query = (this.inputTarget.value || "").trim();
    if (!query) {
      this.showAllBlogs();
      return;
    }

    if (!this.fuse) {
      console.warn("Search not initialized");
      return;
    }

    const hits = this.fuse.search(query);
    const matchingIds = hits.map(h => h.item.id);
    
    this.filterBlogs(matchingIds);
  }

  initializeSearchData() {
    this.blogs = this.blogItemTargets.map((element, index) => {
      const title = element.dataset.blogTitle || "";
      const content = element.dataset.blogContent || "";
      const author = element.dataset.blogAuthor || "";
      const topic = element.dataset.blogTopic || "";
      const tags = element.dataset.blogTags || "";
      
      return {
        id: index,
        element,
        title,
        content,
        author,
        topic,
        tags
      };
    });
  }

  initializeFuseSearch() {
    if (this.blogs.length > 0) {
      this.fuse = new Fuse(this.blogs, {
        keys: [
          { name: "title", weight: 0.5 },
          { name: "content", weight: 0.3 },
          { name: "topic", weight: 0.1 },
          { name: "author", weight: 0.05 },
          { name: "tags", weight: 0.05 }
        ],
        includeScore: true,
        threshold: 0.4,
        ignoreLocation: true,
        minMatchCharLength: 2,
      });
    }
  }

  filterBlogs(matchingIds) {
    this.blogItemTargets.forEach((element, index) => {
      if (matchingIds.includes(index)) {
        element.classList.remove('hidden');
      } else {
        element.classList.add('hidden');
      }
    });
  }

  showAllBlogs() {
    this.blogItemTargets.forEach(element => {
      element.classList.remove('hidden');
    });
  }

}