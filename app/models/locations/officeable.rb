# frozen_string_literal: true

module Locations
  module Officeable
    extend ActiveSupport::Concern

    included do
      WEEKDAYS = [1,2,3,4,5]
    end

    def today_office_hours
      office_hours.find_by(day: Time.now.wday)
    end

    def next_open_office_hours
      return nil if office_hours.all? { |oh| oh.closed? }
      return today_office_hours if !today_office_hours.closed? && (Time.now < today_office_hours.formatted_open_time)
      @next = today_office_hours.next_office_hours
      loop do
        break unless @next.closed?
        @next = @next.next_office_hours
      end
      return @next
    end

    def open_now?
      today_office_hours.open_now?
    end

    def open_same_day?(next_open)
      next_open.day == today_office_hours.day
    end

    def next_open_day
      Date::DAYNAMES[next_open_office_hours.day].first(3)
    end

    def consistent_weekdays_hours?
      week_office_hours = office_hours.where(day: WEEKDAYS)
      return false if week_office_hours.empty?
      base = week_office_hours.first.open_time&.strftime('%H:%M:%S')
      open_time_consistency = week_office_hours.all? do |oh|
        oh.open_time&.strftime("%H:%M:%S") == base
      end
      base = week_office_hours.first.close_time&.strftime("%H:%M:%S")
      close_time_consistency = week_office_hours.all? do |oh|
        oh.close_time&.strftime("%H:%M:%S") == base
      end

      open_time_consistency && close_time_consistency
    end

    def day_hours(day)
      office_hours.find_by(day: day)
    end

  end
end
