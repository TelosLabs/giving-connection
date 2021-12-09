# frozen_string_literal: true

module OfficeHours
  module Searchable
    extend ActiveSupport::Concern

    def open_now?
      return false if closed?
      Time.now.between?(formatted_open_time.to_time, formatted_close_time.to_time)
    end

    def next_office_hours
      check_day = day
      (check_day < 6) ? check_day+=1 : check_day=0
      OfficeHour.find_by(location_id: location_id, day: check_day)
    end
  end
end
