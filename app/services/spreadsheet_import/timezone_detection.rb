require "timezone_finder"

module SpreadsheetImport
  class TimezoneDetection
    IANA_TO_RAILS_TZ = {
      "America/Los_Angeles" => "Pacific Time (US & Canada)",
      "America/New_York" => "Eastern Time (US & Canada)",
      "America/Chicago" => "Central Time (US & Canada)",
      "America/Denver" => "Mountain Time (US & Canada)",
      "America/Anchorage" => "Alaska",
      "Pacific/Honolulu" => "Hawaii",
      "America/Adak" => "America/Adak",
      "America/Phoenix" => "Arizona"
    }.freeze

    def initialize(latitude, longitude)
      @latitude = latitude
      @longitude = longitude
    end

    def call
      tf = TimezoneFinder.create
      iana_tz = tf.timezone_at(lng: @longitude, lat: @latitude)
      IANA_TO_RAILS_TZ[iana_tz] || iana_tz
    end
  end
end
