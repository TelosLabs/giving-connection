const filterStore = {
  filters : new Set(),

  addFilter(filter) {
    this.filters.add(filter);
    this.notifyFiltersChanged();
    console.log("Filter added")
    console.log(this.filters)
  },

  removeFilter(filter) {
    this.filters.delete(filter);
    this.notifyFiltersChanged();
    console.log("Filter removed")
    console.log(this.filters)
  },

  getFilters() {
    return Array.from(this.filters);
  },

  clearFilters() {
    console.log("Filters cleared")
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