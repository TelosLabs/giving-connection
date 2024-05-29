import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]
    static values = { url: String }

    connect() {
        useClickOutside(this)
        this.confirmedMessage = false
    }

    checkUniqueness() {
      const inputValue = this.inputTarget.value;
      fetch(`${this.urlValue}?ein_number=${inputValue}`)
        .then(response => response.json())
        .then(data => {
          if (data.exists && !this.confirmedMessage) {
            if (!confirm("There is already an organization with that EIN. Are you sure you want to use it?")) {
              this.inputTarget.value = ''; // Clear the input if not confirmed
            } else {
              this.confirmedMessage = true // Prevent the message from showing again
            }
          }
        })
        .catch(error => console.error('Error:', error));
    }
}
