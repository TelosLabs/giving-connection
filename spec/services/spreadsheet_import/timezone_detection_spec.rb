require "rails_helper"

RSpec.describe SpreadsheetImport::TimezoneDetection do
  it "returns the correct timezone for New York" do
    service = described_class.new(40.7128, -74.0060)
    result = service.call
    expect(result).to eq("Eastern Time (US & Canada)")
  end
end
