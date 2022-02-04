import { Controller } from "@hotwired/stimulus"
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['form', 'editForm', 'editButton']
  }

  submitForm() {
    let formData = $(this.formTarget).serialize()
    Rails.ajax({
      url: '/alerts',
      type: 'POST',
      data: formData,
      dataType: 'script',
      success: function(data) {
        console.log(data)
      }
    })
  }

  editForm() {
    let formData = $(this.editFormTarget).serialize()
    Rails.ajax({
      url: `/alerts/${this.editButtonTarget.dataset.alertId}`,
      type: 'PUT',
      data: formData,
      dataType: 'script',
      success: function(data) {
        location.reload()
      }
    })
  }
}