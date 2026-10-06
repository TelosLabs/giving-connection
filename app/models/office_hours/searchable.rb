# frozen_string_literal: true

module OfficeHours
  module Searchable
    extend ActiveSupport::Concern

    def open_now?
      return false if closed?

      window = local_window
      window && current_time_in_zone.between?(*window)
    end

    # A location west of Central closes after midnight UTC, and because a `time`
    # column cannot hold the day rollover both endpoints come back rebuilt on
    # today's date — the close landing *before* the open. Push it forward a day
    # so the comparison spans the window the location is actually open for.
    def local_window
      open_at = formatted_open_time
      close_at = formatted_close_time
      return nil if open_at.nil? || close_at.nil?

      close_at += 1.day if close_at <= open_at
      [open_at, close_at]
    end

    def next_office_hours
      check_day = day
      (check_day < 6) ? check_day += 1 : check_day = 0
      OfficeHour.find_by(location_id: location_id, day: check_day)
    end
  end

  def current_time_in_zone
    time_zone.now
  end
end
