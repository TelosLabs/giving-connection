import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["keyword", "location"]

  trackSearch() {
    const keyword = this.hasKeywordTarget ? this.keywordTarget.value.trim() : ""
    const location = this.hasLocationTarget ? this.locationTarget.value.trim() : ""

    window.dataLayer = window.dataLayer || []
    window.dataLayer.push({
      event: "search",
      // null rather than "" when blank, so clearing the keyword doesn't
      // pollute analytics with empty-string search terms.
      search_term: keyword || null,
      category: "Find Help",
      location: location || null
    })
  }
}
