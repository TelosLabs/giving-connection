require "rails_helper"

RSpec.describe LocationGeocoder, type: :service do
  def result(coordinates:, city: nil, state: nil, state_code: nil, postal_code: nil)
    double(
      "Geocoder::Result",
      coordinates: coordinates,
      city: city,
      state: state,
      state_code: state_code,
      postal_code: postal_code
    )
  end

  it "returns coordinates and city for a locality result" do
    allow(Geocoder).to receive(:search).with("Nashville").and_return([
      result(coordinates: [36.16, -86.78], city: "Nashville", state: "Tennessee", state_code: "TN")
    ])

    expect(described_class.call("Nashville")).to eq(
      latitude: 36.16, longitude: -86.78, city: "Nashville"
    )
  end

  it "labels a ZIP result as 'ZIP, ST' when there is no city" do
    allow(Geocoder).to receive(:search).with("90210").and_return([
      result(coordinates: [34.09, -118.4], city: nil, state: "California", state_code: "CA", postal_code: "90210")
    ])

    expect(described_class.call("90210")).to eq(
      latitude: 34.09, longitude: -118.4, city: "90210, CA"
    )
  end

  it "returns nil when there are no results" do
    allow(Geocoder).to receive(:search).and_return([])

    expect(described_class.call("nowhere")).to be_nil
  end

  it "returns nil for a blank query without calling Geocoder" do
    expect(Geocoder).not_to receive(:search)

    expect(described_class.call("  ")).to be_nil
  end

  it "returns nil and never raises when Geocoder errors" do
    allow(Geocoder).to receive(:search).and_raise(StandardError.new("boom"))

    expect { @result = described_class.call("Nashville") }.not_to raise_error
    expect(@result).to be_nil
  end
end
