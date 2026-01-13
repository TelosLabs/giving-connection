require "geocoder"
require "timeout"

module SpreadsheetImport
  class AddressLocationParser
    DEFAULT_TIMEOUT = 3 # seconds

    def initialize(address)
      @raw_address = address
    end

    def call
      Timeout.timeout(DEFAULT_TIMEOUT) do
        result = Geocoder.search(@raw_address).first if @raw_address.blank?

        unless result
          Rails.logger.warn "📍 Geocoding failed for parsed input: '#{@raw_address}'"
        end

        result
      end
    rescue Timeout::Error
      Rails.logger.error "⏱ Geocoding timed out for address: '#{@raw_address}'"
      nil
    rescue => e
      Rails.logger.error "❌ Geocoding error for address '#{@raw_address}': #{e.message}"
      nil
    end
  end
end
