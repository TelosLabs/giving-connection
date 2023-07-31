import { Controller } from "@hotwired/stimulus"
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['form', 'editForm', 'editButton']
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
        let alert = `<div class="flash-success bg-blue-50 fixed z-40 inset-x-2 top-24 rounded-md p-4 max-w-ms mx-auto" data-alert--component-target="notification" data-controller="alert--component">
                      <div class="flex items-center">
                        <div class="flex-shrink-0">
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" class="h-5 w-5 text-blue-400">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                          </svg>
                        </div><div class="ml-3">
                          <p class="text-sm font-medium text-blue-800">Alert created successfully! Go to My Account to view or edit.</p>
                        </div><div class="pl-3 ml-auto">
                          <div class="-mx-1.5 -my-1.5">
                            <button class="inline-flex rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 p-1.5 bg-blue-50 text-blue-500 hover:bg-blue-100 focus:ring-offset-blue-50 focus:ring-blue-600" data-action="alert--component#closeAlert" type="button">
                              <span class="sr-only">Dismiss</span>
                              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 12" fill="none" class="h-3 w-3">
                                <path d="M7.06127 6.00016L11.7801 1.28111C12.0733 0.988169 12.0733 0.512862 11.7801 0.219923C11.4869 -0.0732668 11.0122 -0.0732668 10.719 0.219923L6.00012 4.93897L1.28102 0.219923C0.987847 -0.0732668 0.51306 -0.0732668 0.219883 0.219923C-0.0732943 0.512862 -0.0732943 0.988169 0.219883 1.28111L4.93898 6.00016L0.219883 10.7192C-0.0732943 11.0121 -0.0732943 11.4874 0.219883 11.7804C0.366471 11.9267 0.558587 12 0.750453 12C0.942319 12 1.13444 11.9267 1.28102 11.7801L6.00012 7.06109L10.719 11.7801C10.8656 11.9267 11.0577 12 11.2495 12C11.4414 12 11.6335 11.9267 11.7801 11.7801C12.0733 11.4872 12.0733 11.0119 11.7801 10.719L7.06127 6.00016Z" fill="currentColor"></path>
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>`
        document.getElementById('main-navbar').insertAdjacentHTML("afterend", alert)
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
        let alert = `<div class="flash-success bg-blue-50 fixed z-40 inset-x-2 top-24 rounded-md p-4 max-w-ms mx-auto" data-alert--component-target="notification" data-controller="alert--component">
                      <div class="flex items-center">
                        <div class="flex-shrink-0">
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" class="h-5 w-5 text-blue-400">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                          </svg>
                        </div><div class="ml-3">
                          <p class="text-sm font-medium text-blue-800">Alert updated!</p>
                        </div><div class="pl-3 ml-auto">
                          <div class="-mx-1.5 -my-1.5">
                            <button class="inline-flex rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 p-1.5 bg-blue-50 text-blue-500 hover:bg-blue-100 focus:ring-offset-blue-50 focus:ring-blue-600" data-action="alert--component#closeAlert" type="button">
                              <span class="sr-only">Dismiss</span>
                              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 12" fill="none" class="h-3 w-3">
                                <path d="M7.06127 6.00016L11.7801 1.28111C12.0733 0.988169 12.0733 0.512862 11.7801 0.219923C11.4869 -0.0732668 11.0122 -0.0732668 10.719 0.219923L6.00012 4.93897L1.28102 0.219923C0.987847 -0.0732668 0.51306 -0.0732668 0.219883 0.219923C-0.0732943 0.512862 -0.0732943 0.988169 0.219883 1.28111L4.93898 6.00016L0.219883 10.7192C-0.0732943 11.0121 -0.0732943 11.4874 0.219883 11.7804C0.366471 11.9267 0.558587 12 0.750453 12C0.942319 12 1.13444 11.9267 1.28102 11.7801L6.00012 7.06109L10.719 11.7801C10.8656 11.9267 11.0577 12 11.2495 12C11.4414 12 11.6335 11.9267 11.7801 11.7801C12.0733 11.4872 12.0733 11.0119 11.7801 10.719L7.06127 6.00016Z" fill="currentColor"></path>
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>`
        document.getElementById('main-navbar').insertAdjacentHTML("afterend", alert)
      }
    })
  }
}
