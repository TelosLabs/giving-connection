require "rails_helper"

RSpec.describe SpreadsheetImport::AddressLocationParser do
  it "returns the correct coordinates for an example place" do
    allow(Geocoder).to receive(:search).with("5800 MARMION WAY, LOS ANGELES, CA, 90042").and_return([
      Struct.new(:latitude, :longitude).new(34.1110080, -118.1923320)
    ])

    result = described_class.new("5800 MARMION WAY, LOS ANGELES, CA, 90042").call
    expect(result.latitude).to be_within(0.001).of(34.1110080)
    expect(result.longitude).to be_within(0.001).of(-118.1923320)
  end

  it "returns the correct coordinates for an example place" do
    allow(Geocoder).to receive(:search).with("2133 N HICKS AVE	LOS ANGELES	CA	90032-3643").and_return([
      Struct.new(:latitude, :longitude).new(34.0682933, -118.1909603)
    ])

    result = described_class.new("2133 N HICKS AVE	LOS ANGELES	CA	90032-3643").call
    expect(result.latitude).to be_within(0.001).of(34.0682933)
    expect(result.longitude).to be_within(0.001).of(-118.1909603)
  end
end
