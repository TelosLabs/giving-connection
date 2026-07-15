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

    # The full-week weekday schedule shared by several format variations below.
    def weekday_9_to_5
      week_with(
        1 => {day: 1, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        2 => {day: 2, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        3 => {day: 3, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        4 => {day: 4, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false},
        5 => {day: 5, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false}
      )
    end

    context "with abbreviated day names" do
      it "accepts three-letter abbreviations" do
        expect(described_class.new("Mon - Fri: 9:00 - 17:00").call).to eq(weekday_9_to_5)
      end

      it "accepts single-letter initials" do
        expect(described_class.new("M-F 9:00-17:00").call).to eq(weekday_9_to_5)
      end

      it "accepts variant abbreviations like Tues and Thurs" do
        result = described_class.new("Tues - Thurs 9:00 - 15:00").call
        expected = week_with(
          2 => {day: 2, open_time: offset_time("09:00"), close_time: offset_time("15:00"), closed: false},
          3 => {day: 3, open_time: offset_time("09:00"), close_time: offset_time("15:00"), closed: false},
          4 => {day: 4, open_time: offset_time("09:00"), close_time: offset_time("15:00"), closed: false}
        )
        expect(result).to eq(expected)
      end
    end

    context "with word range separators" do
      it "treats 'to' as a range" do
        expect(described_class.new("Monday to Friday 9:00 - 17:00").call).to eq(weekday_9_to_5)
      end

      it "treats 'through' as a range" do
        expect(described_class.new("Monday through Friday: 9:00 - 17:00").call).to eq(weekday_9_to_5)
      end
    end

    context "with keyword day groups" do
      it "expands 'Weekdays'" do
        expect(described_class.new("Weekdays 9:00-17:00").call).to eq(weekday_9_to_5)
      end

      it "expands 'Weekends'" do
        result = described_class.new("Weekends 10:00 - 14:00").call
        expected = week_with(
          0 => {day: 0, open_time: offset_time("10:00"), close_time: offset_time("14:00"), closed: false},
          6 => {day: 6, open_time: offset_time("10:00"), close_time: offset_time("14:00"), closed: false}
        )
        expect(result).to eq(expected)
      end

      it "expands 'Daily' to the whole week" do
        result = described_class.new("Daily 8:00 - 20:00").call
        overrides = (0..6).to_h { |i| [i, {day: i, open_time: offset_time("08:00"), close_time: offset_time("20:00"), closed: false}] }
        expect(result).to eq(week_with(overrides))
      end
    end

    context "with slash-separated days" do
      it "parses Mon/Wed/Fri" do
        result = described_class.new("Mon/Wed/Fri 10:00-14:00").call
        expected = week_with(
          1 => {day: 1, open_time: offset_time("10:00"), close_time: offset_time("14:00"), closed: false},
          3 => {day: 3, open_time: offset_time("10:00"), close_time: offset_time("14:00"), closed: false},
          5 => {day: 5, open_time: offset_time("10:00"), close_time: offset_time("14:00"), closed: false}
        )
        expect(result).to eq(expected)
      end
    end

    context "with 12-hour and bare-hour times" do
      it "parses am/pm times" do
        expect(described_class.new("Mon-Fri 9am - 5pm").call).to eq(weekday_9_to_5)
      end

      it "reads a bare 9-5 as 9am-5pm" do
        expect(described_class.new("Mon-Fri 9-5").call).to eq(weekday_9_to_5)
      end

      it "keeps a bare morning-to-noon range literal" do
        result = described_class.new("Wed 9-12").call
        expected = week_with(
          3 => {day: 3, open_time: offset_time("09:00"), close_time: offset_time("12:00"), closed: false}
        )
        expect(result).to eq(expected)
      end
    end

    context "with all-day / 24 hour phrasing" do
      it "parses '24 hours'" do
        result = described_class.new("Monday: 24 hours").call
        expected = week_with(
          1 => {day: 1, open_time: "00:00", close_time: "24:00", closed: false}
        )
        expect(result).to eq(expected)
      end
    end

    context "with unrecognized or blank input" do
      it "returns an all-closed week for blank markers without raising" do
        ["NA", "None", "TBD", "By appointment only"].each do |value|
          expect { described_class.new(value).call }.not_to raise_error
          expect(described_class.new(value).call).to all(include(closed: true))
        end
      end

      it "skips an unparseable entry rather than aborting the whole cell" do
        # The first line has an unknown day token; the second must still parse.
        result = described_class.new("Funday 9:00-17:00\nTuesday 9:00-17:00").call
        expect(result[2]).to eq({day: 2, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false})
        expect(result[1]).to include(closed: true)
      end
    end
  end
end
