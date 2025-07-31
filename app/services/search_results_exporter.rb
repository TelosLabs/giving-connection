# SearchResultsExporter
#
# This service exports search results to CSV format for user downloads.
# It includes nonprofit names, descriptions, location information, and contact details.
#
class SearchResultsExporter < ApplicationService
  require "csv"

  def initialize(search_results, search_params = {})
    @search_results = search_results
    @search_params = search_params
  end

  def call
    CSV.generate(headers: true) do |csv|
      # Add headers
      csv << headers

      # Add data rows
      @search_results.each do |result|
        csv << build_row_data(result)
      end
    end
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
      result.name,
      organization&.scope_of_work || "",
      result.address || "",
      extract_city(result.address) || "",
      extract_state(result.address) || "",
      extract_zipcode(result.address) || "",
      result.phone_number&.number || "",
      result.email || organization&.email || "",
      result.website || organization&.website || "",
      organization&.causes&.pluck(:name)&.join(", ") || "",
      organization&.verified? ? "Yes" : "No",
      generate_profile_link(result.id)
    ]
  end

  def extract_city(address)
    return nil if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    return parts[1] if parts.length >= 2
    nil
  end

  def extract_state(address)
    return nil if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    if parts.length >= 3
      # The state is usually the second to last part before zipcode
      state_part = parts[2]
      # Extract state code (2 letters) from "TN 37201"
      state_match = state_part.match(/^([A-Z]{2})\s+\d{5}/)
      return state_match[1] if state_match
      # If no zipcode pattern, just return the state part
      return state_part
    end
    nil
  end

  def extract_zipcode(address)
    return nil if address.blank?

    # Parse address like "123 Main St, Nashville, TN 37201"
    parts = address.split(",").map(&:strip)
    if parts.length >= 3
      # The zipcode is usually the last part
      last_part = parts.last
      # Extract zipcode (5 digits) from "TN 37201" or just "37201"
      zip_match = last_part.match(/(\d{5})/)
      return zip_match[1] if zip_match
    end
    nil
  end

  def generate_profile_link(location_id)
    # Generate the profile link using the same pattern as the existing export
    Rails.application.routes.url_helpers.location_url(location_id)
  rescue
    ""
  end
end
