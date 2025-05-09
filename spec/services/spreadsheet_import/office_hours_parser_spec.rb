require 'rails_helper'

RSpec.describe SpreadsheetImport::OfficeHoursParser do
  it "parses standard ranges" do
    result = described_class.new("Monday - Friday 8:00 - 16:00").call
    expect(result.size).to eq(5)
  end
end
