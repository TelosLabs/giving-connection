require 'geocoder'

module SpreadsheetImport
  class AddressLocationParser

    def initialize(address)
      @address = address
    end

    def call
      Geocoder.search(@address).first
    end
    
  end
end