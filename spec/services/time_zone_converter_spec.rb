require "rails_helper"

RSpec.describe TimeZoneConverter, type: :service do
  describe "time conversion" do
    let(:local_time_zone) { "Pacific Time (US & Canada)" }
    let(:time_str) { "13:00:00.00000" }

    it "converts the time to UTC and then converts it back" do
      converter = described_class.new(local_time_zone)
      utc_time = converter.to_utc(time_str)

      expect(utc_time.zone).to eq("UTC")
      expect(utc_time.hour).to eq(20)

      original_time = converter.to_local(utc_time.strftime("%H:%M:%S"))

      expect(original_time.zone).to eq("PDT")
      expect(original_time.hour).to eq(13)
    end

    it "raises an error if the time given is invalid" do
      converter = described_class.new(local_time_zone)
      expect { converter.to_utc(Time.zone.now) }.to raise_error(ArgumentError, "Invalid time string")
      expect { converter.to_utc("invalid") }.to raise_error(ArgumentError, "Invalid time string")
    end
  end
end
