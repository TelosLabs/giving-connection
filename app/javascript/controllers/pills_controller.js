import { Controller } from "@hotwired/stimulus"
import { useDispatch } from 'stimulus-use'
import Rails from '@rails/ujs'

export default class extends Controller {
  static get targets() {
    return ['form', 'pills', "pillsCounter", "causesPill", "servicesPill", "beneficiaryGroupsPill", "selectAllCausesPill", "selectAllServicesPill", "selectAllBeneficiaryGroupsPill"]
  }

  toggleAllCausesPills() {
    if (this.allPillsAreChecked(this.causesPillTargets) == "allSelected") {
      this.causesPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.causesPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.updatePillsCounter()
    this.form.requestSubmit()
  }

  toggleAllServicesPills() {
    if (this.allPillsAreChecked(this.servicesPillTargets) == "allSelected") {
      this.servicesPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.servicesPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.updatePillsCounter()
    this.submitForm()
  }

  toggleAllBeneficiaryGroupsPills() {
    if (this.allPillsAreChecked(this.beneficiaryGroupsPillTargets) == "allSelected") {
      this.beneficiaryGroupsPillTargets.forEach(pill => {
        pill.checked = false
        pill.removeAttribute('checked')
      })
    } else {
      this.beneficiaryGroupsPillTargets.forEach(pill => {
        pill.checked = true
        pill.setAttribute('checked', true)
      })
    }
    this.updatePillsCounter()
    this.submitForm()
  }

  allPillsAreChecked(pills) {
    let checked_pills = []
    pills.forEach(pill => {
      if (pill.checked) {
        checked_pills.push(pill)
      }
    })
    if (checked_pills.length == pills.length) {
      return "allSelected"
    } else if (checked_pills.length == 0) {
      return "noneSelected"
    } else if (checked_pills.length > 0 && checked_pills.length < pills.length) {
      return "someSelected"
    }
  }

  clearChecked() {
    this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })
    this.pillsTarget.querySelectorAll('input[type="radio"]:checked').forEach(input => {
      input.checked = false
      input.removeAttribute('checked')
    })
    this.pillsCounterTarget.innerHTML = ""
    this.submitForm()
  }

  updatePillsCounter() {
    let checks = this.pillsTarget.querySelectorAll('input[type="checkbox"]:checked').length
    let radio = this.pillsTarget.querySelectorAll('input[type="radio"]:checked').length
    this.pillsCounterTarget.innerHTML = checks + radio
    if (this.allPillsAreChecked(this.causesPillTargets) == "someSelected") {
      this.selectAllCausesPillTarget.checked = false
      this.selectAllCausesPillTarget.removeAttribute('checked')
    }
    if (this.allPillsAreChecked(this.servicesPillTargets) == "someSelected") {
      this.selectAllServicesPillTarget.checked = false
      this.selectAllServicesPillTarget.removeAttribute('checked')
    }
    if (this.allPillsAreChecked(this.beneficiaryGroupsPillTargets) == "someSelected") {
      this.selectAllBeneficiaryGroupsPillTarget.checked = false
      this.selectAllBeneficiaryGroupsPillTarget.removeAttribute('checked')
    }
  }
}
