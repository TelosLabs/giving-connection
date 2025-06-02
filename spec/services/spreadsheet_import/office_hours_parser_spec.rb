require "rails_helper"

RSpec.describe SpreadsheetImport::OfficeHoursParser do
  describe "#call" do
    let(:default_closed_day) do |day|
      { day: day, open_time: nil, close_time: nil, closed: true }
    end

    def week_with(overrides = {})
      (0..6).map do |i|
        overrides[i] || { day: i, open_time: nil, close_time: nil, closed: true }
      end
    end

    it "parses standard ranges" do
      result = described_class.new("Monday - Friday: 8:00 - 16:00").call
      expected = week_with(
        0 => { day: 0, open_time: "08:00", close_time: "16:00", closed: false },
        1 => { day: 1, open_time: "08:00", close_time: "16:00", closed: false },
        2 => { day: 2, open_time: "08:00", close_time: "16:00", closed: false },
        3 => { day: 3, open_time: "08:00", close_time: "16:00", closed: false },
        4 => { day: 4, open_time: "08:00", close_time: "16:00", closed: false }
      )
      expect(result).to eq(expected)
    end

    it "parses non-continuous days" do
      result = described_class.new("Monday, Thursday - Friday: 9:00 - 17:00").call
      expected = week_with(
        0 => { day: 0, open_time: "09:00", close_time: "17:00", closed: false },
        3 => { day: 3, open_time: "09:00", close_time: "17:00", closed: false },
        4 => { day: 4, open_time: "09:00", close_time: "17:00", closed: false }
      )
      expect(result).to eq(expected)
    end

    it "parses different hours" do
      result = described_class.new("Monday: 9:00 - 17:00 & Saturday: 14:00 - 16:00").call
      expected = week_with(
        0 => { day: 0, open_time: "09:00", close_time: "17:00", closed: false },
        5 => { day: 5, open_time: "14:00", close_time: "16:00", closed: false }
      )
      expect(result).to eq(expected)
    end

    it "parses 24/7 format" do
      result = described_class.new("Monday: 24/7").call
      expected = week_with(
        0 => { day: 0, open_time: "00:00", close_time: "24:00", closed: false }
      )
      expect(result).to eq(expected)
    end

    it "parses combining everything" do
      result = described_class.new("Monday, Wednesday-Friday: 9:00 - 17:00 & Saturday, Sunday: 14:00 - 16:00").call
      expected = week_with(
        0 => { day: 0, open_time: "09:00", close_time: "17:00", closed: false },
        2 => { day: 2, open_time: "09:00", close_time: "17:00", closed: false },
        3 => { day: 3, open_time: "09:00", close_time: "17:00", closed: false },
        4 => { day: 4, open_time: "09:00", close_time: "17:00", closed: false },
        5 => { day: 5, open_time: "14:00", close_time: "16:00", closed: false },
        6 => { day: 6, open_time: "14:00", close_time: "16:00", closed: false }
      )
      expect(result).to eq(expected)
    end
  end
end
