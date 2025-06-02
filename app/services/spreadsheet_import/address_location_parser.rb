require "geocoder"
require "timeout"

module SpreadsheetImport
  class AddressLocationParser
    DEFAULT_TIMEOUT = 3 # seconds

    def initialize(address)
      @address = clean_address(address)
    end

    def call
      Timeout.timeout(DEFAULT_TIMEOUT) do
        result = Geocoder.search(@address).first
        unless result
          Rails.logger.warn "📍 Geocoding failed: No result for address: '#{@address}'"
        end
        result
      end
    rescue Timeout::Error
      Rails.logger.error "⏱ Geocoding timed out for address: '#{@address}'"
      nil
    rescue => e
      Rails.logger.error "❌ Geocoding error for address '#{@address}': #{e.message}"
      nil
    end

    private

    def clean_address(raw_address)
      address = raw_address.to_s.strip
      address = address.gsub(/[\t\r\n]+/, " ")
      address.gsub(/\s+/, " ")
    end
  end
end
