require "timezone_finder"

module SpreadsheetImport
  class TimezoneDetection
    def initialize(latitude, longitude)
      @latitude = latitude
      @longitude = longitude
    end

    def call
      tf = TimezoneFinder.create
      tf.timezone_at(lng: @longitude, lat: @latitude)
    end
  end
end
