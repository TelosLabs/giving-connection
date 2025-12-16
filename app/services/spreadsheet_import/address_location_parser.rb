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
        result = try_geocode(@raw_address)

        unless result
          Rails.logger.warn "📍 Geocoding failed for address: '#{@raw_address}'"
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

    private

    def try_geocode(address)
      return nil if address.blank?
      Geocoder.search(address).first
    end
  end
end
