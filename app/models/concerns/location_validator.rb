# frozen_string_literal: true

class LocationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    complete_office_hours
    complete_time_zone
    valid_website_url
  end

  private

  def complete_office_hours
    return true if record.non_standard_office_hours.present? || record.offer_services == false

    unless Time::DAYS_INTO_WEEK.values.sort == record.office_hours.map(&:day).sort
      record.errors.add(:base, "Office hours data is required for the 7 days of the week")
    end
  end

  def valid_website_url
    return true if record.website.blank?
    url = begin
      URI.parse(record.website)
    rescue
      false
    end
    return true if url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS) || url.is_a?(URI::Generic)
    record.organization&.errors&.add(:base, "Website url incorrect format")
  end

  def complete_time_zone
    return true if record.non_standard_office_hours.present? || record.offer_services == false
    return true if record.time_zone.present?

    record.errors.add(:base, "Time zone is required for locations that offer services.")
  end
end
