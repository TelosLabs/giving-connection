import Clipboard from 'stimulus-clipboard'
import { Controller } from "@hotwired/stimulus"

export default class extends Clipboard {
  connect() {
    super.connect()
    console.log('Do what you want here.')
  }

  // Function to override on copy.
  copy(event) {
    console.log(event);
  }

  // Function to override when to input is copied.
  copied() {
    //
  }
}
