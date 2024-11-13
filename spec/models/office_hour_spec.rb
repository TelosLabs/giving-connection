require "rails_helper"

RSpec.describe OfficeHour, type: :model do
  let(:location) { create(:location, :with_office_hours) }
  let(:office_hour) { build(:office_hour, location: location) }

  describe "associations" do
    it "is expected to belong to location" do
      expect(office_hour.location).to eql(location)
    end
  end

  describe "validations" do
    subject { office_hour }

    it { is_expected.to validate_presence_of(:day) }
    it { is_expected.to validate_inclusion_of(:day).in_range(0..6) }
    it { is_expected.to validate_presence_of(:open_time) }
    it { is_expected.to validate_presence_of(:close_time) }
  end

  describe "methods" do
    describe "#time_zone" do
      it "is expected to return time zone as Time Zone object" do
        expect(office_hour.time_zone).to be_a(ActiveSupport::TimeZone)
      end

      it "is expected to have a name that matches the location's time zone " do
        expect(office_hour.time_zone.name).to eql(location.time_zone)
      end

      it "is expected to fallback to default time zone if location time zone is not present" do
        location.time_zone = nil
        expect(office_hour.time_zone.name).to eql("Eastern Time (US & Canada)")
      end
    end
  end

  describe "callbacks" do
    let(:location) { create(:location, :with_office_hours, time_zone: "Pacific Time (US & Canada)") }
    let(:oh) { build(:office_hour, location: location, open_time: "12:00", close_time: "16:00") }

    describe "#convert_times_to_utc" do
      it "converts the time from location's time zone to UTC before saving" do
        subject { oh }

        # Set the open and close times with a specific time zone
        oh.open_time = Time.zone.parse("12:00 PM").in_time_zone("Pacific Time (US & Canada)")
        oh.close_time = Time.zone.parse("4:00 PM").in_time_zone("Pacific Time (US & Canada)")

        oh.save!

        expect(oh.open_time.zone).to eql("UTC")
        expect(oh.close_time.zone).to eql("UTC")
        expect(oh.open_time.hour).to eql(20)
        expect(oh.close_time.hour).to eql(0)
      end
    end
  end
end
