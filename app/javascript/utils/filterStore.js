const filterStore = {
  filters : new Set(),

  setInitialFilters(filters) {
    filters.forEach(filter => {
      filterStore.addFilter(filter)
    })
  },

  addFilter(filter) {
    this.filters.add(filter);
    this.notifyFiltersChanged();
  },

  removeFilter(filter) {
    this.filters.delete(filter);
    this.notifyFiltersChanged();
  },

  getFilters() {
    return Array.from(this.filters);
  },

  clearFilters() {
    this.filters.clear();
    this.notifyFiltersChanged();
  },

  notifyFiltersChanged() {
    const event = new CustomEvent("filters-changed", {
      detail: this.getFilters(),
      bubbles: true,
      cancelable: true
    });
    window.dispatchEvent(event);
  }
};

export default filterStore;