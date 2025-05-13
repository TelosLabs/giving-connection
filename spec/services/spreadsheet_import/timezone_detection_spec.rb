require 'rails_helper'

RSpec.describe SpreadsheetImport::TimezoneDetection do
  it "returns the correct timezone for New York" do
    service = described_class.new(40.7128, -74.0060)
    result = service.call
    expect(result).to eq('America/New_York')
  end

  it 'returns the correct timezone for London' do
    service = described_class.new(51.5074, -0.1278)
    result = service.call
    expect(result).to eq('Europe/London')
  end
end
