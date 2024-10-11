# frozen_string_literal: true

class OrganizationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    at_least_one_main_location
    valid_website_url
    valid_donation_url
    valid_volunteer_url
  end

  private

  def single_main_location
    record.errors.add(:base, "Only one main location is required") if record.locations.select(&:main?).size > 1
  end

  def at_least_one_main_location
    record.errors.add(:base, "At least one main location is required") if record.locations.select(&:main?).empty?
  end

  def valid_website_url
    valid_url(record.website, :website)
  end

  def valid_donation_url
    valid_url(record.donation_link, :donation_link)
  end

  def valid_volunteer_url
    valid_url(record.volunteer_link, :volunteer_link)
  end

  def valid_url(raw_url, attribute)
    return true if raw_url.blank?
    url = begin
      URI.parse(raw_url)
    rescue
      false
    end
    unless url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS) || url.is_a?(URI::Generic)
      record.errors.add(attribute, "URL incorrect format")
    end
  end
end
