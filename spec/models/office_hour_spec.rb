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

  describe "the open-before-close invariant" do
    let(:location) { create(:location, :with_office_hours, time_zone: "Pacific Time (US & Canada)") }

    it "rejects a range that closes before it opens" do
      inverted = build(:office_hour, location: location, day: 1, open_time: "17:00", close_time: "09:00")

      expect(inverted).not_to be_valid
      expect(inverted.errors[:close_time]).to include("must be after the opening time")
    end

    # The error used to be attached to record.location.organization, which on a
    # later edit is a different instance from the one being saved — so inverting
    # a persisted row saved cleanly and no validation ever caught it.
    it "still rejects the inversion when a persisted row is edited on its own" do
      office_hour = create(:office_hour, location: location, day: 1, open_time: "09:00", close_time: "17:00")

      expect(office_hour.reload.update(open_time: "18:00", close_time: "08:30")).to be(false)
      expect(office_hour.errors[:close_time]).to include("must be after the opening time")
    end

    it "accepts a range that closes after it opens" do
      expect(build(:office_hour, location: location, day: 1, open_time: "09:00", close_time: "17:00")).to be_valid
    end
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
    let(:location) { build(:location, time_zone: "Pacific Time (US & Canada)", offer_services: true, non_standard_office_hours: nil) }
    let(:oh) { build(:office_hour, location: location, day: 1) }

    describe "#convert_times_to_utc" do
      it "converts the time from location's time zone to UTC before saving" do
        # Set times as strings (like form input)
        oh.open_time = "12:00"
        oh.close_time = "16:00"

        oh.save!

        # Verify times are stored in UTC
        expect(oh.open_time.zone).to eql("UTC")
        expect(oh.close_time.zone).to eql("UTC")

        # Pacific Time is UTC-8 (PST) or UTC-7 (PDT)
        # 12:00 PM PST/PDT becomes 20:00/19:00 UTC
        # 4:00 PM PST/PDT becomes 00:00/23:00 UTC (next day/same day)
        expect([19, 20]).to include(oh.open_time.hour)
        expect([23, 0]).to include(oh.close_time.hour)
      end

      it "handles Time objects correctly" do
        # Set times as Time objects in Pacific timezone
        pacific_tz = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]
        oh.open_time = pacific_tz.parse("12:00")
        oh.close_time = pacific_tz.parse("16:00")

        oh.save!

        expect(oh.open_time.zone).to eql("UTC")
        expect(oh.close_time.zone).to eql("UTC")
      end
    end

    describe "formatted time methods" do
      it "stores times in UTC and displays in local timezone" do
        # Set and save times
        oh.open_time = "09:00"
        oh.close_time = "17:00"
        oh.save!

        # Get formatted times
        formatted_open = oh.formatted_open_time
        formatted_close = oh.formatted_close_time

        # Verify storage in UTC
        expect(oh.open_time.zone).to eq("UTC")
        expect(oh.close_time.zone).to eq("UTC")

        # Should be displayed in Pacific timezone
        expect(formatted_open.zone).to match(/P[DS]T/)
        expect(formatted_close.zone).to match(/P[DS]T/)

        # Verify that formatting returns valid Time objects
        expect(formatted_open).to be_a(Time)
        expect(formatted_close).to be_a(Time)
      end

      it "handles string input consistently" do
        # Test the most common use case: string input from forms
        oh.open_time = "10:30"
        oh.close_time = "18:45"
        oh.save!

        # Verify storage in UTC
        expect(oh.open_time.zone).to eq("UTC")
        expect(oh.close_time.zone).to eq("UTC")

        # Verify formatted times are in correct timezone and represent reasonable times
        formatted_open = oh.formatted_open_time
        formatted_close = oh.formatted_close_time

        expect(formatted_open.zone).to match(/P[DS]T/)
        expect(formatted_close.zone).to match(/P[DS]T/)

        # The formatted times should be reasonable office hours (between 6 AM and 11 PM)
        expect(formatted_open.hour).to be_between(6, 23)
        expect(formatted_close.hour).to be_between(6, 23)

        # Close time should be after open time on the same day
        expect(formatted_close.hour).to be >= formatted_open.hour
      end
    end
  end
end
