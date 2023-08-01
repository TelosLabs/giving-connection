# frozen_string_literal: true

class LocationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    complete_office_hours
    valid_website_url
  end

  private

  def complete_office_hours
    return true if record.appointment_only? || record.always_open?

    record.organization.errors.add(:base, 'Office hours data is required for the 7 days of the week') unless Time::DAYS_INTO_WEEK.values.sort == record.office_hours.map(&:day).sort
  end

  def valid_website_url
    return true if record.website.blank?
    url = URI.parse(record.website) rescue false
    return true if url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS) || url.kind_of?(URI::Generic)
    record.organization.errors.add(:base, 'Website url incorrect format')
  end
end
