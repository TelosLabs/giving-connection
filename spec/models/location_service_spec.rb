# frozen_string_literal: true

# == Schema Information
#
# Table name: location_services
#
#  id          :bigint           not null, primary key
#  description :string
#  location_id :bigint           not null
#  service_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "rails_helper"

RSpec.describe LocationService, type: :model do
  context "LocationService model validation test" do
    subject { create(:location_service) }

    it "ensures location_service can be created" do
      expect(subject).to be_valid
    end
  end

  describe "search index sync" do
    it "enqueues a search_vector refresh for the location's organization on create" do
      organization = create(:organization)
      location = organization.locations.first
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      create(:location_service, location: location)

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(organization.id)
    end

    it "enqueues a search_vector refresh for the location's organization on destroy" do
      organization = create(:organization)
      location = organization.locations.first
      location_service = create(:location_service, location: location)
      allow(Locations::RefreshSearchVectorJob).to receive(:coalesce_for_organization)

      location_service.destroy

      expect(Locations::RefreshSearchVectorJob).to have_received(:coalesce_for_organization).with(organization.id)
    end
  end
end
