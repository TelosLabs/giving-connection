require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  let(:location) { create(:location) }
  let(:office_hour) { create(:office_hour, location: location) }
  subject { create(:office_hour) }

  describe "associations" do
    it "is expected to belong to location" do
      expect(office_hour.location).to eql(location)
    end
  end

  describe "validations" do
    it { should validate_presence_of(:day) }
    it { should validate_inclusion_of(:day).in_range(0..6) }
    it { should validate_presence_of(:open_time) }
    it { should validate_presence_of(:close_time) }
  end
end
