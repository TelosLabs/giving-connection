# frozen_string_literal: true

class LocationDecorator < ApplicationDecorator
  delegate_all

  def closed_office_hours_display
    next_opened_day = object.next_open_office_hours
    return "" unless next_opened_day

    if object.open_same_day?(next_opened_day)
      "Opens at #{next_opened_day.open_time&.strftime("%l:%M %p")}"
    else
      "Opens on #{object.next_open_day} at #{next_opened_day.formatted_open_time&.strftime("%l:%M %p")} (#{next_opened_day.formatted_open_time.zone})"
    end
  end

  def working_hours
    return "Closed" if open_time_for_display.nil? && close_time_for_display.nil?

    "#{open_time_for_display} - #{close_time_for_display} (#{monday_office_hours&.formatted_open_time&.zone})"
  end

  def display_day_working_hours(office_hour)
    return "Closed" if office_hour&.closed?

    "#{office_hour&.formatted_open_time&.strftime("%l:%M %p")} - #{office_hour&.formatted_close_time&.strftime("%l:%M %p")}  (#{office_hour&.formatted_open_time&.zone})"
  end

  def monday_office_hours
    object.office_hours.find_by(day: Time::DAYS_INTO_WEEK[:monday])
  end

  def open_time_for_display
    monday_office_hours&.formatted_open_time&.strftime("%l:%M %p")
  end

  def close_time_for_display
    monday_office_hours&.formatted_close_time&.strftime("%l:%M %p")
  end

  def street
    address.split(",").slice(0)
  end

  def city_state_zipcode
    address.split(",").drop(1).join(", ")
  end

  def non_standard_office_hours_for_display
    return if object.non_standard_office_hours.empty?

    return "By Appointment Only" if object.appointment_only?
    return "No Set Business Hours - Call to Inquire" if object.no_set_business_hours?
    "Always Open" if object.always_open?
  end
end
