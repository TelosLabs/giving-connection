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

  xdescribe "callbacks" do
    let(:location) { create(:location, :with_office_hours, time_zone: "Pacific Time (US & Canada)") }
    let(:oh) { build(:office_hour, location: location, open_time: "12:00", close_time: "16:00") }

    subject { oh }

    it "converts the time zone from the location to EST before saving" do
      expect(oh).to receive(:convert_time_to_est)
      oh.save!

      expect(oh.open_time.zone).to eql("EST")
      expect(oh.close_time.zone).to eql("EST")
      expect(oh.open_time.hour).to eql(15)
      expect(oh.close_time.hour).to eql(19)
    end
  end
end
