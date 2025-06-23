require "geocoder"
require "timeout"

module SpreadsheetImport
  class AddressLocationParser
    DEFAULT_TIMEOUT = 3 # seconds

    def initialize(address)
      @raw_address = address
      @cleaned_address = clean_address(address)
    end

    def call
      Timeout.timeout(DEFAULT_TIMEOUT) do
        result = try_geocode(@cleaned_address)

        if result.nil? && po_box?(@cleaned_address)
          zip = extract_zip(@cleaned_address)
          result = try_geocode(zip) if zip
        end

        if result.nil?
          simplified_address = remove_apartment_or_suite(@cleaned_address)
          result = try_geocode(simplified_address)
        end

        unless result
          Rails.logger.warn "📍 Geocoding failed: No result for address: '#{@raw_address}'"
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

    def clean_address(address)
      address.to_s.strip
             .gsub(/[\t\r\n]+/, ", ") # normalize newlines and tabs
             .gsub(/,+/, ",")         # collapse multiple commas
             .gsub(/\s+/, " ")        # normalize spaces
             .gsub(/ ,/, ",")         # remove space before commas
    end

    def po_box?(address)
      address.upcase.match?(/\bP\.?O\.?\s*BOX\b/)
    end

    def extract_zip(address)
      address[/\b\d{5}(?:-\d{4})?\b/]
    end

    def remove_apartment_or_suite(address)
      address.gsub(/\b(APT|SUITE|STE|UNIT|FLOOR|#)\s*\w+/i, "").strip
    end
  end
end
