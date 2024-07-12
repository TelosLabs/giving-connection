const filterStore  = {
  filters: new Set(),

  setInitialFilters(filters) {
    filters.forEach(filter => {
      filterStore.addFilter(filter.value, filter.category)
    })
  },

  addFilter(value, category) {
    this.filters.add({ value, category });
    this.notifyFiltersChanged();
  },

  removeFilter(value, category) {
    this.filters.forEach(filter => {
      if (filter.value === value && filter.category === category) {
        this.filters.delete(filter);
      }
    });
    this.notifyFiltersChanged();
  },

  clearFilters() {
    this.filters.clear();
    this.notifyFiltersChanged();
  },

  getFilters() {
    return Array.from(this.filters);
  },

  hasFilter(value, category) {
    return Array.from(this.filters).some(filter => filter.value === value && filter.category === category);
  },

  notifyFiltersChanged() {
    const event = new CustomEvent("filters-changed", {
      detail: this.getFilters(),
      bubbles: true,
      cancelable: true
    });
    window.dispatchEvent(event);
  }
}

export default filterStore;
