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
        #llm_result = RubyLlm.format_address(@raw_address)

        #if llm_result.is_a?(Hash) && llm_result[:error]
        #  Rails.logger.warn "❌ LLM failed to parse address: #{@raw_address}"
        #end

        #parsed_address = build_parsed_address(llm_result)
        #result = try_geocode(parsed_address) || try_geocode(@raw_address)
        result = try_geocode(@raw_address)

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

    private

    def try_geocode(address)
      return nil if address.blank?
      Geocoder.search(address).first
    end

    def build_parsed_address(parsed)
      return nil unless parsed.is_a?(Hash)

      address_line1 = parsed["address_line1"]
      city = parsed["city"]
      state = parsed["state"]
      zip = parsed["zip"]

      if address_line1.nil?
        [city, state, zip].compact.join(", ")
      elsif zip.nil?
        [address_line1, city, state].compact.join(", ")
      else
        [address_line1, city, state, zip].compact.join(", ")
      end
    end
  end
end
