import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  connect() {
    consumer.subscriptions.create(
      "BookmarkChannel",
      { received: this.received.bind(this) }
    ) 
  }

  received(data) {
    console.log(data)

    if (data["method"] == "create") {
      document.getElementById(`location_${data["location_id"]}`).remove()
      document.getElementById(`new_favorite_location_${data["location_id"]}`).insertAdjacentHTML("afterend", data["marked_partial"])
    } else {
      document.getElementById(`favorite_location_${data["favorite_location_id"]}`).remove()
      document.getElementById(`new_favorite_location_${data["location_id"]}`).insertAdjacentHTML('afterend', data["unmarked_partial"])
    }    
  }
}
