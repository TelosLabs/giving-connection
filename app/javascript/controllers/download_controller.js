import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    resultIds: Array
  }

  submit() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.urlValue
    form.target = '_blank'

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)

    // Add result IDs
    this.resultIdsValue.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'result_ids[]'
      input.value = id
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
    document.body.removeChild(form)
  }
}