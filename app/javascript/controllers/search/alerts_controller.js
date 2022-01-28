import { Controller } from "@hotwired/stimulus"
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['form']
  }

  connect() {
  }

  submitForm() {
    let formData = $(this.formTarget).serialize()
    Rails.ajax({
      url: '/alerts',
      type: 'POST',
      data: formData,
      dataType: 'script',
      success: function(data) {
      }
    })
  }
}