require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:organization) { create(:organization) }
  subject { create(:location, organization: organization) }

  describe "associations" do
    it { should belong_to(:organization).optional }
    it { should have_many(:office_hours) }
    it { should have_many(:favorite_locations).dependent(:destroy) }
    it { should have_many(:tags) }
    it { should have_many(:location_services).dependent(:destroy) }
    it { should have_many(:services) }
    it { should have_many(:causes) }
    it { should have_many_attached(:images) }
    it { should have_one(:phone_number).dependent(:destroy) }
    it { should have_one(:social_media) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
    it { should validate_inclusion_of(:main).in_array([true, false]) }
    it { should validate_inclusion_of(:physical).in_array([true, false]) }
    it { should validate_inclusion_of(:offer_services).in_array([true, false]) }
    it { should validate_inclusion_of(:appointment_only).in_array([true, false]) }
  end
end
