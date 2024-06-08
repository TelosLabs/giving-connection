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
  validates :open_time, presence: true, unless: :closed_or_does_not_offers_service?
  validates :close_time, presence: true, unless: :closed_or_does_not_offers_service?

  before_validation :closed_if_does_not_offers_service
  before_validation :clean_time, if: :closed?

  def day_name
    Date::DAYNAMES[day]
  end

  def formatted_open_time
    return nil unless open_time
    now = current_time_in_zone
    open_time.change({year: now.year, month: now.month, day: now.day})
    in_local_time(open_time)
  end

  def formatted_close_time
    return nil unless close_time

    now = current_time_in_zone
    close_time.change({year: now.year, month: now.month, day: now.day})
    in_local_time(close_time)
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

  def closed_or_does_not_offers_service?
    closed? || !location.offer_services
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
