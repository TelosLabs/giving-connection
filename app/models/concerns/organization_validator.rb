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
    url = URI.parse(record.website) rescue false
    unless url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS) || url.kind_of?(URI::Generic) 
      record.errors.add(:website, 'URL incorrect format')
    end
  end
end
