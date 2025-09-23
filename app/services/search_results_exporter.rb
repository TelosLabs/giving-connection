# frozen_string_literal: true

# SearchResultsExporter
#
# This service exports search results to CSV format for user downloads.
# It includes nonprofit names, descriptions, location information, and contact details.
#
class SearchResultsExporter < ApplicationService
  require "csv"

  def initialize(search_results)
    @search_results = search_results
    validate_input!
  end

  def call
    CSV.generate(headers: true) do |csv|
      csv << headers
      @search_results.find_each { |result| csv << build_row_data(result) }
    end
  rescue => e
    Rails.logger.error "CSV generation failed: #{e.message}"
    raise "Failed to generate CSV export"
  end

  private

  def headers
    [
      "Nonprofit Name",
      "Description",
      "Address",
      "City",
      "State",
      "Zip Code",
      "Phone Number",
      "Email",
      "Website",
      "Causes",
      "Verified",
      "Profile Link"
    ]
  end

  def build_row_data(result)
    organization = result.organization

    [
      result.name || "",
      organization&.scope_of_work || "",
      result.address || "",
      extract_city(result.address),
      extract_state(result.address),
      extract_zipcode(result.address),
      result.organization&.phone_number || "",
      result.email || organization&.email || "",
      result.website || organization&.website || "",
      organization&.causes&.pluck(:name)&.join(", ") || "",
      organization&.verified? ? "Yes" : "No",
      generate_profile_link(result.id)
    ]
  end

  def extract_city(address)
    return "" if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    (parts.length >= 2) ? parts[1] : ""
  end

  def extract_state(address)
    return "" if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    return "" if parts.length < 3

    # Extract state code from "TN 37201"
    state_part = parts[2]
    state_match = state_part.match(/^([A-Z]{2})\s+\d{5}/)
    state_match ? state_match[1] : state_part
  end

  def extract_zipcode(address)
    return "" if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    return "" if parts.length < 3

    # Extract zipcode from last part
    last_part = parts.last
    zip_match = last_part.match(/(\d{5})/)
    zip_match ? zip_match[1] : ""
  end

  def generate_profile_link(location_id)
    host = Rails.application.credentials.dig(Rails.env.to_sym, :host)
    Rails.application.routes.url_helpers.location_url(location_id, host: host)
  rescue
    ""
  end

  def validate_input!
    raise ArgumentError, "Search results cannot be nil" if @search_results.nil?
  end

  def safe_field_access
    # Helper method to safely access potentially nil fields
    yield
  rescue
    ""
  end
end
