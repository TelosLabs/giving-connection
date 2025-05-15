require "geocoder"

module SpreadsheetImport
  class AddressLocationParser
    def initialize(address)
      @address = clean_address(address)
    end

    def call
      Geocoder.search(@address).first
    end

    private

    def clean_address(raw_address)
      address = raw_address.strip
      address = address.gsub(/[\t\r\n]+/, " ")
      address.gsub(/\s+/, " ")
    end
  end
end
