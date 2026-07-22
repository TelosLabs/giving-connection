require "geocoder"
require "timeout"

# Resolves a typed city/ZIP string (or a picked suggestion's label) into
# coordinates + a normalized city label, server-side, via the `geocoder` gem
# (Google Geocoding API, keyed by `google_geocoder_api_key`). This replaces the
# browser's `google.maps.Geocoder` + client-side `cityFromGeocode` parsing.
#
# Returns { latitude:, longitude:, city: } or nil. NEVER raises.
class LocationGeocoder < ApplicationService
  DEFAULT_TIMEOUT = 3 # seconds

  def initialize(query)
    @query = query.to_s.strip
  end

  def call
    return nil if @query.blank?

    Timeout.timeout(DEFAULT_TIMEOUT) do
      result = Geocoder.search(@query).first
      return nil unless result&.coordinates

      {
        latitude: result.coordinates[0],
        longitude: result.coordinates[1],
        city: city_label(result)
      }
    end
  rescue Timeout::Error
    Rails.logger.error "⏱ LocationGeocoder timed out for '#{@query}'"
    nil
  rescue => e
    Rails.logger.error "📍 LocationGeocoder error for '#{@query}': #{e.message}"
    nil
  end

  private

  # Mirror the old client-side preference: locality, else "ZIP, ST", else state,
  # else fall back to whatever the user typed.
  def city_label(result)
    return result.city if result.city.present?

    if result.postal_code.present?
      return result.state_code.present? ? "#{result.postal_code}, #{result.state_code}" : result.postal_code
    end

    result.state.presence || @query
  end
end
