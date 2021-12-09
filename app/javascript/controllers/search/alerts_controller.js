import { Controller } from "@hotwired/stimulus"
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['form']
  }

  connect() {
    // console.log('connect')
  }

  submitForm() {
    console.log('submitform')
    let formData = $(this.formTarget).serialize()
    console.log(formData)
    Rails.ajax({
      url: '/alerts',
      type: 'POST',
      data: formData,
      dataType: 'script',
      success: function(data) {
        console.log(data)
      },
    })
  }

}