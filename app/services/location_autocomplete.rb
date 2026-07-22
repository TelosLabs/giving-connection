require "net/http"
require "uri"
require "json"

# Server-side proxy for Google Place Autocomplete (city predictions as the user
# types). Replaces the browser's `google.maps.places.AutocompleteService` so the
# API key stays server-side and prediction rendering happens through Rails.
#
# Returns an array of { description:, place_id: } hashes (at most MAX_RESULTS),
# or [] on any failure. It NEVER raises — a dead autocomplete must degrade to the
# preset city list, not break the search bar.
#
# Requires the *Places API* to be enabled on `google_geocoder_api_key`. If it is
# not (or billing/quota fails), Google returns REQUEST_DENIED/OVER_QUERY_LIMIT and
# we log + return [] so the UI falls back to presets.
class LocationAutocomplete < ApplicationService
  ENDPOINT = "https://maps.googleapis.com/maps/api/place/autocomplete/json".freeze
  MAX_RESULTS = 5
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 3
  MIN_QUERY_LENGTH = 2

  def initialize(query)
    @query = query.to_s.strip
  end

  def call
    return [] if @query.length < MIN_QUERY_LENGTH
    return [] if api_key.blank?

    body = request_predictions
    return [] unless body

    parse(body)
  rescue => e
    Rails.logger.error "📍 LocationAutocomplete error for '#{@query}': #{e.message}"
    []
  end

  private

  def api_key
    Rails.application.credentials.dig(:google_geocoder_api_key)
  end

  def request_predictions
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(
      input: @query,
      types: "(cities)",
      components: "country:us",
      key: api_key
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    response = http.get(uri.request_uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def parse(body)
    json = JSON.parse(body)
    status = json["status"]

    # ZERO_RESULTS is normal ("no matches"); everything else non-OK is an error
    # worth logging (quota/billing/key/Places-not-enabled) but still yields [].
    if status == "ZERO_RESULTS"
      return []
    elsif status != "OK"
      Rails.logger.warn "📍 LocationAutocomplete non-OK status '#{status}' for '#{@query}': #{json["error_message"]}"
      return []
    end

    Array(json["predictions"]).first(MAX_RESULTS).map do |prediction|
      {
        description: format_label(prediction["description"]),
        place_id: prediction["place_id"]
      }
    end
  end

  # Drop the trailing country ("Nashville, TN, USA" -> "Nashville, TN").
  def format_label(text)
    text.to_s.sub(/,?\s*(USA|United States)\z/i, "").strip
  end
end
