require "rails_helper"

RSpec.describe TimeZoneConverter, type: :service do
  describe "#convert_to_est" do
    it "converts the time to Eastern Time considering DST" do
      time_zone = "Pacific Time (US & Canada)"
      est_time_zone = "Eastern Time (US & Canada)"
      time_str = "2024-07-01 13:00:00.00000" # 1:00 PM in DST
      converter = TimeZoneConverter.new(time_zone, est_time_zone)
      converted_time = converter.from_time_zone_to_est(time_str)
      expect(converted_time.zone).to eq("EDT")
      expect(converted_time.hour).to eq(16)
    end

    it "converts from EST to a provided time zone" do
      time_zone = "Pacific Time (US & Canada)"
      est_time_zone = "Eastern Time (US & Canada)"
      time_str = "2024-01-01 13:00:00.00000" # 1:00 PM in EST
      converter = TimeZoneConverter.new(time_zone, est_time_zone)
      converted_time = converter.from_est_to_time_zone(time_str)
      expect(converted_time.zone).to eq("PST")
      expect(converted_time.hour).to eq(10)
    end
  end
end
