// app/javascript/controllers/events_controller.js
import { Controller } from "@hotwired/stimulus"

const MAX_SIZE_IN_BYTES = 5 * 1024 * 1024

export default class extends Controller {
  static targets = ["startTime", "endTime", "startDate", "endDate", "clearEndButton", "allDayCheckbox", "imagePreview", "locationContainer"]

    setEndDate() {
        if (this.startDateTarget.value && !this.endDateTarget.value) {
            this.endDateTarget.value = this.startDateTarget.value
        }
    }
  
    showClearButton() {
        if (this.endTimeTarget.value) {
            this.clearEndButtonTarget.classList.remove('hidden')
        } else {
            this.clearEndButtonTarget.classList.add('hidden')
        }
    }

    clearEndTime() {
        const endTimeInput = this.endTimeTarget
        endTimeInput.value = ""
        this.clearEndButtonTarget.classList.add('hidden')
    }

    toggleTimeInputs() {
        const isAllDay = this.allDayCheckboxTarget.checked
        if (isAllDay) {
            this.startTimeTarget.disabled = true
            this.startTimeTarget.classList.add('opacity-50', 'cursor-not-allowed')
            this.endTimeTarget.disabled = true
            this.endTimeTarget.classList.add('opacity-50', 'cursor-not-allowed')
        } else {
            this.startTimeTarget.disabled = false
            this.startTimeTarget.classList.remove('opacity-50', 'cursor-not-allowed')
            this.endTimeTarget.disabled = false
            this.endTimeTarget.classList.remove('opacity-50', 'cursor-not-allowed')
        }
    }

    toggleLocation(event) {
        const isRemote = event.target.value === "true"
        this.locationContainerTarget.style.display = isRemote ? 'none' : 'flex';
    }

    previewImage(event) {
        const file = event.target.files[0]
        if (file) {
            if (file.size > MAX_SIZE_IN_BYTES) {
                alert("this file size exceeds the 5MB limit. Please upload a smaller image.")
                event.target.value = ""
                if (this.hasImagePreviewTarget) {
                    this.imagePreviewTarget.classList.add('hidden')
                }
                return
            }
            
            const reader = new FileReader()
            reader.onload = (e) => {
                this.imagePreviewTarget.src = e.target.result
                this.imagePreviewTarget.classList.remove('hidden')
            }
            reader.readAsDataURL(file)
        } else {
            this.imagePreviewTarget.classList.add('hidden')
        }
    }
 }