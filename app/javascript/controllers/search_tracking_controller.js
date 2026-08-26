import { Controller } from "@hotwired/stimulus"

// Pushes a `search` event into the GTM dataLayer when a visitor runs a search.
//
// The form this rides on is also the filter form: every pill, distance button
// and city change calls search#submitForm, which is requestSubmit(), which
// dispatches a real submit event. Firing on every one of those would turn one
// search into five and corrupt the term counts this exists to produce, so a
// push only happens when the keyword actually changed.
//
// trackedKeywordValue is the keyword the current page was rendered for. It has
// to come from the server rather than from instance state, because submitting
// the form navigates — Turbo replaces the body, this controller reconnects, and
// anything held in memory is gone by the time the next submit happens.
export default class extends Controller {
  static targets = ["keyword", "location"]
  static values = {
    origin: String,
    category: { type: String, default: "Find Help" },
    trackedKeyword: String
  }

  connect() {
    this.lastTracked = this.trackedKeywordValue.trim()
  }

  trackSearch() {
    const keyword = this.hasKeywordTarget ? this.keywordTarget.value.trim() : ""
    if (!keyword || keyword === this.lastTracked) return
    this.lastTracked = keyword

    const location = this.hasLocationTarget ? this.locationTarget.value.trim() : ""

    window.dataLayer = window.dataLayer || []
    window.dataLayer.push({
      event: "search",
      search_term: keyword,
      search_category: this.categoryValue,
      search_origin: this.originValue || null,
      search_location: location || null
    })
  }
}
