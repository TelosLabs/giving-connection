# frozen_string_literal: true

class OrganizationValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    at_least_one_main_location
    valid_website_url
  end

  private

  def single_main_location
    record.errors.add(:base, 'Only one main location is required') if record.locations.select(&:main?).size > 1
  end

  def at_least_one_main_location
    record.errors.add(:base, 'At least one main location is required') if record.locations.select(&:main?).empty?
  end

  def valid_website_url
    return true if record.website.blank?

    url = begin
      URI.parse(record.website)
    rescue StandardError
      false
    end
    record.errors.add(:website, 'URL incorrect format') unless url.is_a?(URI::HTTP) || url.is_a?(URI::HTTPS) || url.is_a?(URI::Generic)
  end
end
