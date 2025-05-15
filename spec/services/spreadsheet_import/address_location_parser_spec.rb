require 'rails_helper'

RSpec.describe SpreadsheetImport::AddressLocationParser do
  it "returns the correct coordinates for New York" do
    result = described_class.new("New York, NY").call
    expect(result.latitude).to eq(40.7127281)
    expect(result.longitude).to eq(-74.0060152)
  end

  it "returns the correct coordinates for an example place" do
    result = described_class.new("5800 MARMION WAY, LOS ANGELES, CA, 90042").call
    expect(result.latitude).to eq(34.1110080)
    expect(result.longitude).to eq(-118.1923320)
  end

  it "returns the correct coordinates for an example place" do
    result = described_class.new("2133 N HICKS AVE	LOS ANGELES	CA	90032-3643").call
    expect(result.latitude).to eq(34.0682933)
    expect(result.longitude).to eq(-118.1909603)
  end
end
