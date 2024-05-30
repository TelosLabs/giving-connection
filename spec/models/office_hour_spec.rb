require "rails_helper"

RSpec.describe OfficeHour, type: :model do
  let(:location) { create(:location, :with_office_hours) }
  let(:office_hour) { build(:office_hour, location: location) }

  subject { office_hour }

  describe "associations" do
    it "is expected to belong to location" do
      expect(office_hour.location).to eql(location)
    end
  end

  describe "validations" do
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
end
