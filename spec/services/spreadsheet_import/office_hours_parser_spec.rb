require "rails_helper"

# The parser returns local wall-clock times unchanged; conversion to UTC is the
# OfficeHour model's responsibility (TimeZoneConvertible).
def offset_time(time_str)
  return time_str if time_str.nil?

  Time.zone.parse(time_str).strftime("%H:%M")
end

RSpec.describe SpreadsheetImport::OfficeHoursParser do
  describe "#call" do
    let(:default_closed_day) do |day|
      {day: day, open_time: nil, close_time: nil, closed: true}
    end

    def week_with(overrides = {})
      (0..6).map do |i|
        overrides[i] || {day: i, open_time: nil, close_time: nil, closed: true}
      end
    end

    it "parses standard ranges" do
      result = described_class.new("Monday - Friday: 8:00 - 16:00").call
      expected = week_with(
        1 => {day: 1, open_time: offset_time("08:00"), close_time: offset_time("16:00"), closed: false},
        2 => {day: 2, open_time: offset_time("08:00"), close_time: offset_time("16:00"), closed: false},
        3 => {day: 3, open_time: offset_time("08:00"), close_time: offset_time("16:00"), closed: false},
        4 => {day: 4, open_time: offset_time("08:00"), close_time: offset_time("16:00"), closed: false},
        5 => {day: 5, open_time: offset_time("08:00"), close_time: offset_time("16:00"), closed: false}
      )
      expect(result).to eq(expected)
    end

    it "parses non-continuous days" do
      result = described_class.new("Monday, Thursday - Friday: 9:00 - 17:00").call
      expected = week_with(
        1 => {day: 1, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        4 => {day: 4, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        5 => {day: 5, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false}
      )
      expect(result).to eq(expected)
    end

    it "parses different hours" do
      result = described_class.new("Monday: 9:00 - 17:00 & Saturday: 14:00 - 16:00").call
      expected = week_with(
        1 => {day: 1, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        6 => {day: 6, open_time: offset_time("14:00"), close_time: offset_time("16:00"), closed: false}
      )
      expect(result).to eq(expected)
    end

    it "parses 24/7 format" do
      result = described_class.new("Monday: 24/7").call
      expected = week_with(
        1 => {day: 1, open_time: "00:00", close_time: "24:00", closed: false}
      )
      expect(result).to eq(expected)
    end

    it "parses newline-separated entries with dash separators (no colon)" do
      # Spreadsheet cells often place each day range on its own line and separate
      # the days from the times with a tab/dash rather than a colon.
      input = "Thursday–Sunday\t- 10:00 - 15:00\nMonday–Wednesday - Closed"
      result = described_class.new(input).call
      expected = week_with(
        4 => {day: 4, open_time: offset_time("10:00"), close_time: offset_time("15:00"), closed: false},
        5 => {day: 5, open_time: offset_time("10:00"), close_time: offset_time("15:00"), closed: false},
        6 => {day: 6, open_time: offset_time("10:00"), close_time: offset_time("15:00"), closed: false},
        0 => {day: 0, open_time: offset_time("10:00"), close_time: offset_time("15:00"), closed: false}
      )
      expect(result).to eq(expected)
    end

    it "parses combining everything" do
      result = described_class.new("Monday, Wednesday-Friday: 9:00 - 17:00 & Saturday, Sunday: 14:00 - 16:00").call
      expected = week_with(
        1 => {day: 1, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        3 => {day: 3, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        4 => {day: 4, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        5 => {day: 5, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        6 => {day: 6, open_time: offset_time("14:00"), close_time: offset_time("16:00"), closed: false},
        0 => {day: 0, open_time: offset_time("14:00"), close_time: offset_time("16:00"), closed: false}
      )
      expect(result).to eq(expected)
    end
  end
end
