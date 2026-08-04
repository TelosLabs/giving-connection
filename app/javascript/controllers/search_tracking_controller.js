import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["keyword", "location"]
  static values = { origin: String }

  trackSearch() {
    const keyword = this.hasKeywordTarget ? this.keywordTarget.value.trim() : ""
    const location = this.hasLocationTarget ? this.locationTarget.value.trim() : ""

    window.dataLayer = window.dataLayer || []
    window.dataLayer.push({
      event: "search",
      search_term: keyword || null,
      category: "Find Help",
      search_origin: this.originValue || null,
      location: location || null
    })
  }
}
