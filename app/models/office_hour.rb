# frozen_string_literal: true

# == Schema Information
#
# Table name: office_hours
#
#  id          :bigint           not null, primary key
#  day         :integer          not null
#  open_time   :time
#  close_time  :time
#  closed      :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  location_id :bigint
#
class OfficeHour < ActiveRecord::Base
  include OfficeHours::Searchable
  include TimeZoneConvertible
  validates_with OfficeHoursValidator

  belongs_to :location, touch: true

  validates :day, presence: true, inclusion: 0..6
  validates :open_time, presence: true, unless: :office_hours_not_applicable?
  validates :close_time, presence: true, unless: :office_hours_not_applicable?
  validates :day, uniqueness: {scope: :location_id, message: "already has office hours for this location"}

  before_validation :closed_if_does_not_offers_service
  before_validation :clean_time, if: :closed?

  def day_name
    Date::DAYNAMES[day]
  end

  def formatted_open_time
    return nil unless open_time
    # The open_time is stored as UTC time, so we need to convert it to local time
    # Create a datetime with today's date and the stored time
    now = current_time_in_zone
    utc_datetime = open_time.change({year: now.year, month: now.month, day: now.day})
    # Convert from UTC to local timezone
    local_timezone = ActiveSupport::TimeZone[time_zone]
    utc_datetime.in_time_zone(local_timezone)
  end

  def formatted_close_time
    return nil unless close_time
    # The close_time is stored as UTC time, so we need to convert it to local time
    # Create a datetime with today's date and the stored time
    now = current_time_in_zone
    utc_datetime = close_time.change({year: now.year, month: now.month, day: now.day})
    # Convert from UTC to local timezone
    local_timezone = ActiveSupport::TimeZone[time_zone]
    utc_datetime.in_time_zone(local_timezone)
  end

  def time_zone
    location_time_zone = location&.time_zone.presence || ""
    ActiveSupport::TimeZone[location_time_zone] || default_time_zone
  end

  private

  def current_time_in_zone
    time_zone.now
  end

  def default_time_zone
    ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
  end

  def in_local_time(time)
    Rails.logger.debug { "Debug info: Nathaly office_hour in_local_time at #{Time.current}" }
    Rails.logger.debug { "Debug info: Nathaly office_hour in_local_time current var time: #{time}" }
    Rails.logger.debug { "Debug info: Nathaly office_hour in_local_time current var time_zone: #{time_zone}" }

    # Convert from UTC back to local timezone using the same approach as the concern
    local_timezone = ActiveSupport::TimeZone[time_zone]
    time.in_time_zone(local_timezone)
  end

  def office_hours_not_applicable?
    closed? || !location.offer_services || location.non_standard_office_hours.present?
  end

  def clean_time
    self.open_time = nil
    self.close_time = nil
  end

  def closed_if_does_not_offers_service
    unless location.offer_services
      self.closed = true
    end
  end
end
