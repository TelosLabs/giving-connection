// app/javascript/controllers/events_controller.js
import { Controller } from "@hotwired/stimulus"
import $ from "jquery"
import moment from "moment"

export default class extends Controller {
  static targets = ["list", "calendar", "listButton", "calendarButton", "filters", "daterange"]
  static values = { 
    numParams: Number,
    daterangeParam: String 
  }

  connect() {
    this.initializeDaterangePicker()
  }

  toggleList(event) {
    const isList = event.currentTarget.dataset.type === "list"
    
    if (isList) {
      // Show list and hide calendar
      this.listTarget.classList.remove('hidden')
      this.calendarTarget.classList.add('hidden', 'h-0', 'w-0')
      
      // Change button styles
      this.listButtonTarget.classList.add('bg-gray-200')
      this.calendarButtonTarget.classList.remove('bg-gray-200')
    } else {
      // Hide list
      this.listTarget.classList.add('hidden')
      
      // Show calendar container with proper dimensions 
      this.calendarTarget.classList.remove('hidden', 'h-0', 'w-0')
      
      // Change button styles
      this.listButtonTarget.classList.remove('bg-gray-200')
      this.calendarButtonTarget.classList.add('bg-gray-200')

      if (window.calendar) {
        window.calendar.render()
      }
    }
  }

  showFilters(event) {
    const show = event.currentTarget.dataset.show === "true"
    
    if (show) {
      this.filtersTarget.classList.remove('hidden')
    } else {
      this.filtersTarget.classList.add('hidden')
    }
  }

  clearFilters() {
    window.location.href = '/events/explore'
  }

  parseDateRange(dateRangeStr) {
    if (!dateRangeStr) return { start: null, end: null }
    
    // Decode URL-encoded characters
    const decodedStr = decodeURIComponent(dateRangeStr)
    
    // Split by the hyphen to get start and end parts
    const parts = decodedStr.split(' - ')
    if (parts.length !== 2) return { start: null, end: null }
    
    const startStr = parts[0]
    const endStr = parts[1]
    
    // Parse dates directly with moment
    const startDate = moment(startStr, 'M/D hh:mm A')
    const endDate = moment(endStr, 'M/D hh:mm A')
    
    return {
      start: startDate.isValid() ? startDate : null,
      end: endDate.isValid() ? endDate : null
    }
  }

  initializeDaterangePicker() {
    if (!this.hasDaterangeTarget) return
    
    // Initialize daterangepicker with appropriate options
    const daterangepickerOptions = {
      timePicker: true,
      autoUpdateInput: false, // Don't update input until user selects a date range
      locale: {
        format: 'M/D h:mm A',
        cancelLabel: 'Clear',
        applyLabel: 'Apply'
      },
      drops: 'up',
      opens: 'center'
    }
    
    // Only set startDate and endDate if there's a valid daterange parameter
    if (this.daterangeParamValue) {
      const parsedDates = this.parseDateRange(this.daterangeParamValue)
      if (parsedDates.start && parsedDates.end) {
        daterangepickerOptions.startDate = parsedDates.start
        daterangepickerOptions.endDate = parsedDates.end
        daterangepickerOptions.autoUpdateInput = true // Update input with the existing date range
      }
    }
    
    // Initialize daterangepicker
    const dateRangePicker = $(this.daterangeTarget).daterangepicker(daterangepickerOptions)
    
    // Add event listeners to update the input value when user selects a date range
    dateRangePicker.on('apply.daterangepicker', (ev, picker) => {
      $(this.daterangeTarget).val(picker.startDate.format('M/D h:mm A') + ' - ' + picker.endDate.format('M/D h:mm A'))
    })
    
    // Clear the input when user cancels
    dateRangePicker.on('cancel.daterangepicker', (ev, picker) => {
      $(this.daterangeTarget).val('')
    })
  }
}