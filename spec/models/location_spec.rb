require "rails_helper"
require "active_support/testing/time_helpers"

RSpec.describe Location, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "associations" do
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to have_many(:office_hours) }
    it { is_expected.to have_many(:favorite_locations).dependent(:destroy) }
    it { is_expected.to have_many(:tags) }
    it { is_expected.to have_many(:location_services).dependent(:destroy) }
    it { is_expected.to have_many(:services) }
    it { is_expected.to have_many(:causes) }
    it { is_expected.to have_many_attached(:images) }
    it { is_expected.to have_one(:phone_number).dependent(:destroy) }
    it { is_expected.to have_one(:social_media) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:latitude) }
    it { is_expected.to validate_presence_of(:longitude) }
    it { is_expected.to validate_inclusion_of(:main).in_array([true, false]) }
    it { is_expected.to validate_inclusion_of(:offer_services).in_array([true, false]) }

    it "validates non standard office hours" do
      expect { build(:location, non_standard_office_hours: :always_closed) }.to raise_error(ArgumentError).with_message(/is not a valid non_standard_office_hours/)
    end

    it "can create a location without non standard office hours" do
      expect(build(:location, :with_office_hours, non_standard_office_hours: nil)).to be_valid
    end

    describe "LocationValidator" do
      let(:location) { build(:location) }

      it "validates complete office hours" do
        expect { location.validate! }.to raise_error(ActiveRecord::RecordInvalid).with_message(/Office hours data is required for the 7 days of the week/)
      end

      it "validates time zone" do
        expect { location.validate! }.to raise_error(ActiveRecord::RecordInvalid).with_message(/Time zone is required for locations that offer services./)
      end
    end
  end

  describe "methods" do
    let(:location) { create(:location, :with_office_hours) }

    describe "#open_now?" do
      it "is expected to return true if location is open now" do
        travel_to Time.zone.parse("1970-01-01 08:00:30") do
          expect(location.open_now?).to eq(true)
        end
      end

      it "is expected to return false if location is closed now" do
        travel_to Time.zone.parse("1970-01-01 07:59:59") do
          expect(location.open_now?).to eq(false)
        end
      end
    end
  end
end
