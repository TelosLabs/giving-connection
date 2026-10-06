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

    # Not "24:00": a `time` column reads that as the next day's midnight, which
    # round-trips back to 00:00 and persists a zero-length window.
    it "parses 24/7 format" do
      result = described_class.new("Monday: 24/7").call
      expected = week_with(
        1 => {day: 1, open_time: "00:00", close_time: "23:59", closed: false}
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
          1 => {day: 1, open_time: "00:00", close_time: "23:59", closed: false}
        )
        expect(result).to eq(expected)
      end

      it "parses 'all day' without a colon" do
        result = described_class.new("Mon all day").call
        expect(result[1]).to eq({day: 1, open_time: "00:00", close_time: "23:59", closed: false})
      end

      it "reports a day-less all-day cell as always_open rather than as hours" do
        parser = described_class.new("Open 24 hours")
        expect(parser.call).to eq([])
        expect(parser.non_standard).to eq("always_open")
      end

      it "reports an all-week all-day cell as always_open" do
        parser = described_class.new("Daily 24 hours")
        expect(parser.call).to eq([])
        expect(parser.non_standard).to eq("always_open")
      end
    end

    context "with unrecognized or blank input" do
      # Returning a week of closed rows here would publish the organization as
      # "Closed" seven days a week and suppress the importer's
      # "no set business hours" fallback. No rows is the honest answer.
      it "returns no rows for blank markers without raising" do
        ["", "NA", "N/A", "n.a.", "None", "TBD", "Unknown", "-", "--", "–"].each do |value|
          expect { described_class.new(value).call }.not_to raise_error
          expect(described_class.new(value).call).to eq([]), "expected #{value.inspect} to yield no rows"
        end
      end

      it "returns no rows and warns when nothing in the cell can be read" do
        ["Funday 9:00-17:00", "Call for hours", "Monday 25:00-30:00"].each do |value|
          parser = described_class.new(value)
          expect(parser.call).to eq([]), "expected #{value.inspect} to yield no rows"
          expect(parser.warnings).to be_present
        end
      end

      it "reports an appointment-only cell through non_standard, not as a closed week" do
        parser = described_class.new("By appointment only")
        expect(parser.call).to eq([])
        expect(parser.non_standard).to eq("appointment_only")
      end

      it "keeps a whole-cell 'Closed' as a genuinely closed week" do
        expect(described_class.new("Closed").call).to all(include(closed: true))
      end

      it "skips an unparseable entry rather than aborting the whole cell" do
        # The first line has an unknown day token; the second must still parse.
        parser = described_class.new("Funday 9:00-17:00\nTuesday 9:00-17:00")
        result = parser.call
        expect(result[2]).to eq({day: 2, open_time: offset_time("09:00"), close_time: offset_time("17:00"), closed: false})
        expect(result[1]).to include(closed: true)
        expect(parser.warnings.join).to include("Funday")
      end
    end

    context "with a trailing clause after real hours" do
      it "does not let a sibling segment's 'closed' wipe out the week" do
        [
          "Mon-Fri 9:00-17:00, Sat closed",
          "Mon-Fri 9:00-17:00 (closed holidays)",
          "Mon-Fri 9:00-17:00 & Sat Closed",
          "Mon-Fri 9:00-17:00, Sat by appointment"
        ].each do |input|
          expect(described_class.new(input).call).to eq(weekday_9_to_5), "failed for #{input.inspect}"
        end
      end

      it "keeps an explicitly closed sibling day closed" do
        result = described_class.new("Mon-Fri 9:00-17:00, Sat closed").call
        expect(result[6]).to include(closed: true)
      end
    end

    context "with comma-separated day/time segments" do
      it "keeps both segments" do
        result = described_class.new("Mon-Wed 9-5, Thu 10-2").call
        expect(result[1]).to include(open_time: offset_time("09:00"), close_time: offset_time("17:00"))
        expect(result[3]).to include(open_time: offset_time("09:00"), close_time: offset_time("17:00"))
        expect(result[4]).to include(open_time: offset_time("10:00"), close_time: offset_time("14:00"))
      end

      it "keeps both segments when they are only separated by a space" do
        result = described_class.new("Mon - Fri 9:00 - 17:00 Sat 10:00 - 14:00").call
        expect(result[5]).to include(open_time: offset_time("09:00"), close_time: offset_time("17:00"))
        expect(result[6]).to include(open_time: offset_time("10:00"), close_time: offset_time("14:00"))
      end

      it "does not split a day list that has no times of its own" do
        result = described_class.new("Monday, Thursday - Friday: 9:00 - 17:00").call
        expect(result[1]).to include(closed: false)
      end

      it "warns when a split shift offers a second range there is nowhere to put" do
        parser = described_class.new("Mon-Fri 8-12, 1-5")
        expect(parser.call[1]).to include(open_time: offset_time("08:00"), close_time: offset_time("12:00"))
        expect(parser.warnings.join).to include("only the first time range")
      end

      it "treats ';' as an entry separator" do
        result = described_class.new("Mon-Wed 9:00-17:00; Thu 10:00-14:00").call
        expect(result[1]).to include(open_time: offset_time("09:00"))
        expect(result[4]).to include(open_time: offset_time("10:00"))
      end
    end

    context "with '&' between days rather than between schedules" do
      it "keeps every day of a '&' day list" do
        result = described_class.new("Sat & Sun 10:00-14:00").call
        expect(result[6]).to include(open_time: offset_time("10:00"), closed: false)
        expect(result[0]).to include(open_time: offset_time("10:00"), closed: false)
      end

      it "keeps a group and a day joined by '&'" do
        result = described_class.new("Weekdays & Sat 9:00-17:00").call
        expect(result[1]).to include(closed: false)
        expect(result[6]).to include(closed: false)
      end

      it "still splits '&' when both sides carry their own times" do
        result = described_class.new("Mon-Fri 9-5 & Sat 10-2").call
        expect(result[1]).to include(open_time: offset_time("09:00"), close_time: offset_time("17:00"))
        expect(result[6]).to include(open_time: offset_time("10:00"), close_time: offset_time("14:00"))
      end
    end

    context "with multi-day tokens" do
      it "keeps every day of a space- or 'and'-separated list" do
        {
          "Mon Wed Fri 9-5" => [1, 3, 5],
          "Mon and Wed 9-5" => [1, 3],
          "Mon-Wed-Fri 9-5" => [1, 3, 5],
          "T/Th 9-5" => [2, 4],
          "MWF 9-5" => [1, 3, 5]
        }.each do |input, open_days|
          result = described_class.new(input).call
          expect(result.reject { |row| row[:closed] }.pluck(:day)).to eq(open_days), "failed for #{input.inspect}"
        end
      end

      it "expands 'Weekdays and Saturday'" do
        result = described_class.new("Weekdays and Saturday 9:00-17:00").call
        expect(result.reject { |row| row[:closed] }.pluck(:day)).to eq([1, 2, 3, 4, 5, 6])
      end

      it "expands the remaining keyword groups" do
        ["Everyday 8:00-20:00", "All week 8:00-20:00", "Business days 8:00-20:00", "7 days a week 8:00-20:00"].each do |input|
          expect(described_class.new(input).call.reject { |row| row[:closed] }).to be_present, "failed for #{input.inspect}"
        end
      end

      it "rejects a day spec whose parts do not all resolve" do
        parser = described_class.new("W/ appointment 9-5")
        expect(parser.call).to eq([])
        expect(parser.non_standard).to eq("appointment_only")
      end
    end

    context "with word range separators beyond 'to'" do
      it "treats til/till/until as a range when a time follows" do
        ["Mon-Fri 9:00 til 17:00", "Mon-Fri 9:00 till 17:00", "Mon-Fri 9:00 until 17:00"].each do |input|
          expect(described_class.new(input).call).to eq(weekday_9_to_5), "failed for #{input.inspect}"
        end
      end

      it "leaves prose alone" do
        result = described_class.new("Tuesday 9:00 - 17:00 until further notice").call
        expect(result[2]).to include(open_time: offset_time("09:00"), close_time: offset_time("17:00"))
      end
    end

    context "with an ambiguous bare-hour range" do
      it "reads the classic 9-5 shape as morning to afternoon" do
        {"Mon 9-5" => ["09:00", "17:00"], "Mon 12-1" => ["12:00", "13:00"], "Mon 9-12" => ["09:00", "12:00"]}
          .each do |input, (open_time, close_time)|
          expect(described_class.new(input).call[1])
            .to include(open_time: offset_time(open_time), close_time: offset_time(close_time)), "failed for #{input.inspect}"
        end
      end

      # Guessing here is what silently published "1-5" as one in the morning.
      it "refuses to guess anything else" do
        ["Sun 1-5", "Mon 1-9", "Tue 2-6", "Mon 5-5", "Mon 0-0", "Mon 12-12", "Mon 18-2"].each do |input|
          parser = described_class.new(input)
          expect(parser.call).to eq([]), "expected #{input.inspect} to yield no rows"
          expect(parser.warnings).to be_present
        end
      end
    end

    context "with a meridiem on only one side" do
      it "carries the meridiem across rather than inverting the range" do
        ["Mon 9am-5", "Mon 9:00 - 5:00", "Mon 9:30 to 5:30", "Mon 9-5pm"].each do |input|
          expect(described_class.new(input).call[1]).to include(closed: false), "failed for #{input.inspect}"
          expect(described_class.new(input).call[1][:close_time]).to start_with("17:"), "failed for #{input.inspect}"
        end
      end

      it "normalizes dot-separated times" do
        expect(described_class.new("Mon 8.30-16.30").call[1])
          .to include(open_time: offset_time("08:30"), close_time: offset_time("16:30"))
      end

      it "rejects an impossible meridiem hour" do
        expect(described_class.new("Mon 13pm-15pm").call).to eq([])
      end

      it "rejects a range that still runs backwards" do
        ["Mon 9pm-2am", "Mon 20:00-02:00", "Mon 12pm-12am"].each do |input|
          expect(described_class.new(input).call).to eq([]), "expected #{input.inspect} to yield no rows"
        end
      end
    end
  end
end
