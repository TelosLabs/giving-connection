require "rails_helper"

RSpec.describe Location, type: :model do
  let(:organization) { create(:organization) }

  subject { create(:location, organization: organization) }

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
      expect(build(:location, non_standard_office_hours: nil, organization: organization)).to be_valid
    end
  end
end
