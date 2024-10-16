import flatpickr from 'flatpickr'

function bindDateTimePickers() {
  [...document.querySelectorAll('[data-type="time"]')].forEach((time) => {
    flatpickr(time, {
      enableTime: true,
      enableSeconds: true,
      noCalendar: true,
      altInput: true,
      altFormat: ' h:i:S K',
      dateFormat: 'H:i:S' // H:i
    })
  });

  [...document.querySelectorAll('[data-type="datetime"]')].forEach((time) => {
    flatpickr(time, {
      enableTime: true,
      altInput: true,
      altFormat: 'F J (D), Y - h:i:S K',
      dateFormat: 'Z' // Y-m-d H:i
    })
  });

  [...document.querySelectorAll('[data-type="date"]')].forEach((date) => {
    flatpickr(date, {
      altInput: true,
      altFormat: "F j, Y",
      dateFormat: "Y-m-d"
    })
  });
}

document.addEventListener("turbo:load", function () {
  bindDateTimePickers()
})
