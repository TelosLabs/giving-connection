# frozen_string_literal: true

class OrganizationValidator < ActiveModel::Validator
  # Schemes that must never reach an href, whatever the decorator does with them.
  UNSAFE_URL_SCHEMES = %w[javascript data vbscript file blob].freeze

  attr_reader :record

  def validate(record)
    @record = record
    single_main_location
    # at_least_one_main_location
    valid_website_url
    valid_donation_url
    valid_in_kind_donation_url
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

  def valid_in_kind_donation_url
    valid_url(record.in_kind_donation_link, :in_kind_donation_link, require_http: true)
  end

  def valid_volunteer_url
    valid_url(record.volunteer_link, :volunteer_link)
  end

  def valid_url(raw_url, attribute, require_http: false)
    return true if raw_url.blank?

    url = begin
      URI.parse(raw_url)
    rescue URI::InvalidURIError, TypeError
      nil
    end

    return true if url.is_a?(URI::HTTP) # URI::HTTPS subclasses URI::HTTP

    if url.nil? || require_http || UNSAFE_URL_SCHEMES.include?(url.scheme&.downcase)
      record.errors.add(attribute, "URL incorrect format")
    end
  end
end
