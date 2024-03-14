# frozen_string_literal: true

module OfficeHoursHelper
  def weekdays
    [
      {label: 'Monday', value: 0},
      {label: 'Tuesday', value: 1},
      {label: 'Wednesday', value: 2},
      {label: 'Thursday', value: 3},
      {label: 'Friday', value: 4},
      {label: 'Saturday', value: 5},
      {label: 'Sunday', value: 6}
    ]
  end
end
