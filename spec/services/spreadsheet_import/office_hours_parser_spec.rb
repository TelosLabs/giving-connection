require "rails_helper"

RSpec.describe SpreadsheetImport::OfficeHoursParser do
  describe "#call" do
    it "parses standard ranges" do
      result = described_class.new("Monday - Friday: 8:00 - 16:00").call
      expect(result).to eq(
        %w[Monday Tuesday Wednesday Thursday Friday].map do |day|
          {day: day, opens_at: "08:00", closes_at: "16:00"}
        end
      )
    end

    it "parses non-continuous days" do
      result = described_class.new("Monday, Thursday - Friday: 9:00 - 17:00").call
      expect(result).to eq(
        %w[Monday Thursday Friday].map do |day|
          {day: day, opens_at: "09:00", closes_at: "17:00"}
        end
      )
    end

    it "parses different hours" do
      result = described_class.new("Monday: 9:00 - 17:00 & Saturday: 14:00 - 16:00").call
      expect(result).to eq([
        {day: "Monday", opens_at: "09:00", closes_at: "17:00"},
        {day: "Saturday", opens_at: "14:00", closes_at: "16:00"}
      ])
    end

    it "parses 24/7 format" do
      result = described_class.new("Monday: 24/7").call
      expect(result).to eq([
        {day: "Monday", opens_at: "00:00", closes_at: "24:00"}
      ])
    end

    it "parses combining everything" do
      result = described_class.new("Monday, Wednesday-Friday: 9:00 - 17:00 & Saturday, Sunday: 14:00 - 16:00").call
      expect(result).to eq([
        {day: "Monday", opens_at: "09:00", closes_at: "17:00"},
        {day: "Wednesday", opens_at: "09:00", closes_at: "17:00"},
        {day: "Thursday", opens_at: "09:00", closes_at: "17:00"},
        {day: "Friday", opens_at: "09:00", closes_at: "17:00"},
        {day: "Saturday", opens_at: "14:00", closes_at: "16:00"},
        {day: "Sunday", opens_at: "14:00", closes_at: "16:00"}
      ])
    end
  end
end
