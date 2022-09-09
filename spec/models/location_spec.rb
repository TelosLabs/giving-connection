require 'rails_helper'

RSpec.describe Location, type: :model do
  describe "associations" do 

    describe "belongs to an organization" do 
      let(:organization) { create(:organization) }
      let(:location) { create(:location, organization: organization) }

      it "should return the same organization" do
        expect(location.organization).to eql(organization)
      end

      context "organization not provided" do
        let(:location_without_organization) { create(:location, organization: nil) }
        
        it "should be created" do
          expect(Location.find(location_without_organization.id)).to eql(location_without_organization)
        end
      end
    end

    describe "has many office_hours" do
      let(:location) { create(:location) }
      let!(:many_office_hours) do
        3.times { create(:office_hour, location: location) }
      end

      it "should have 3 office hours" do
        expect(location.office_hours.length).to be(3)
      end
    end

    describe "has many favorite_locations" do
      let(:location1) { create(:location) }
      let!(:many_favorite_locations) do
        3.times { create(:favorite_location, location: location1) }
      end

      it "should have 3 favorite locations" do
        expect(location1.favorite_locations.length).to be(3)
      end 

      context "location destroyed" do
        let(:location2) { create(:location) }
        let!(:favorite_location) { create(:favorite_location, location: location2) }

        it "favorite location should be automatically deleted" do
          fav_location_id = favorite_location.id
          location2.destroy
          expect{FavoriteLocation.find(fav_location_id)}.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "has many tags through organization" do
      let(:organization) { create(:organization) }
      let(:location) { create(:location, organization: organization) }
      let!(:tag1) { create(:tag, organization: organization) }
      let!(:tag2) { create(:tag, organization: organization) }

      it "should have 2 tags" do 
        expect(location.tags.include?(tag1)).to be(true)
        expect(location.tags.include?(tag2)).to be(true)
      end
    end

    describe "has many location_services" do 
      let(:location1) { create(:location) }
      let!(:many_location_services) do
        3.times { create(:location_service, location: location1) }
      end

      it "should have 3 location services" do
        expect(location1.location_services.length).to be(3)
      end 

      context "location destroyed" do
        let(:location2) { create(:location) }
        let!(:location_service) { create(:location_service, location: location2) }

        it "location services should be automatically deleted" do
          location_service_id = location_service.id
          location2.destroy
          expect{FavoriteLocation.find(location_service_id)}.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "has many services through location_service" do
      let(:location) { create(:location) }
      let(:service_1) { create(:service) }
      let(:service_2) { create(:service) }
      # location_service is a join table
      let!(:location_service_1) { create(:location_service, location: location, service: service_1) }
      let!(:location_service_2) { create(:location_service, location: location, service: service_2) }

      it "should offer 2 services" do
        offered_services = location.services
        expect(offered_services.include?(service_1)).to be(true)
        expect(offered_services.include?(service_2)).to be(true)
      end
    end

    describe "has many causes through organization" do
      let(:cause_1) { create(:cause) }
      let(:cause_2) { create(:cause) }
      # The `causes { [association(:cause)] }` line in organization factory 
      # creates 2 records for the organization_cause join table
      let!(:organization) { create(:organization, causes: [cause_1, cause_2]) }
      let(:location) { create(:location, organization: organization) }

      it "location should have 2 causes" do
        expect(location.causes.length).to be(2)
      end
    end

    fdescribe "has many attached images" do 
      subject { create(:location) }

      it { should have_many_attached(:images) }
    end

    describe "has one phone number" do 
      let(:location1) { create(:location) }
      let!(:phone_number1) { create(:phone_number, location: location1)}

      it "should have phone number" do
        expect(location1.phone_number).to eql(phone_number1)
      end 

      context "location destroyed" do
        let(:location2) { create(:location) }
        let!(:phone_number2) { create(:phone_number, location: location2) }

        it "phone number should be automatically deleted" do
          phone_id = phone_number2.id
          location2.destroy
          expect{FavoriteLocation.find(phone_id)}.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "has social media through organization" do
      let(:organization) { create(:organization) }
      let(:location) { create(:location, organization: organization) }
      let!(:social_media) { create(:social_media, organization: organization) }

      it "should have social media acounts" do
        expect(location.social_media).to eql(social_media)
      end
    end
  end

  describe "validations" do
    subject { build(:location) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
    # Apparently shoulda matchers has a conflict with lonlat because of the lonlat_geo_point callback
    it "is expected to validate that :lonlat cannot be empty/falsy" do
      expect(subject.valid? && subject.lonlat != nil ).to be(true)
    end
  end

  describe "scopes" do
    let!(:org) { create(:organization) }
    let!(:org_headquarters) { create(:location, main: true, organization: org) }
    let!(:org_additional_location) { create(:location, main: false, organization: org) }
    let!(:random_location) { create(:location, po_box: true) }

    it "should retrieve only main locations" do
      expect(Location.main.include?(org_headquarters) ).to be(true)
      expect(Location.main.include?(org_additional_location)).to be(false)
    end

    it "fetches only additional locations" do
      expect(Location.additional.include?(org_additional_location)).to be(true)
      expect(Location.additional.include?(org_headquarters) ).to be(false)
    end

    it "retireves only locations with po_box" do
      # po_box is false by default
      expect(Location.besides_po_boxes.include?(org_headquarters)).to be(true)
      expect(Location.besides_po_boxes.include?(random_location) ).to be(false)
    end

    it "should retrieve only locations of active orgs" do
      # Organizations are active by default
      expect(Location.active.include?(org_headquarters) && Location.active.include?(org_additional_location)).to be(true)
      expect(Location.active.include?(random_location) ).to be(false)
    end
  end
  
  describe "delegations" do
    let(:org) { create(:organization) }
    let!(:social_media) { create(:social_media, organization: org) }
    let(:location) { create(:location, organization: org) }

    it "should return the same social media obj as its organization" do
      expect(location.social_media).to equal(org.social_media)
    end
  end

  describe "nested attributes" do
    
    describe "office_hours" do
      let(:performer) { create(:location, office_hours_attributes: [{ day: 2, closed: true }]) }
      
      include_examples('creates a new object through nested attributes', OfficeHour)
      
      context "office_hour attributes are blank" do
        let(:performer_blank) { create(:location, office_hours_attributes: [{}]) }
        
        include_examples("doesn't create a new object because nested attributes are blank", OfficeHour)
      end

      context "destroying associated record" do
        
        it "should destroy a OfficeHour record" do
          my_location = performer
          my_office_hours = performer.office_hours.first
          my_location.update(
            name: 'A cooler name',
            office_hours_attributes: [ { id: my_office_hours.id, _destroy: true } ]
          )

          expect{ my_office_hours.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "location_services" do
      let(:service) { create(:service) }
      let(:performer) { create(:location, location_services_attributes: [{ description: 'Lorem ipsum', service: service }]) }
      
      include_examples('creates a new object through nested attributes', LocationService)
      
      context "location_services attributes are blank" do
        let(:performer_blank) { create(:location, location_services_attributes: [{}]) }

        include_examples("doesn't create a new object because nested attributes are blank", LocationService)
      end

      context "destroying associated record" do
        
        it "should destroy a LocationService record" do
          my_location = performer
          my_loc_servs = performer.location_services.first
          my_location.update(
            name: 'A way cooler name',
            location_services_attributes: [ { id: my_loc_servs.id, _destroy: true } ]
          )

          expect{ my_loc_servs.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "phone_number" do
      let(:performer) { create(:location, phone_number_attributes: { number: '123 4567 8910', main: true}) }

      include_examples('creates a new object through nested attributes', PhoneNumber)

      context "phone_number attributes are blank" do
        let(:performer_blank) { create(:location, phone_number_attributes: {}) }

        include_examples("doesn't create a new object because nested attributes are blank", PhoneNumber)
      end

      context "updating phone_number" do
        it "should update main status" do
          my_location = performer
          my_phone_number = performer.phone_number
          my_location.update(
            name: 'a super name',
            phone_number_attributes: { id: my_phone_number.id, main: false }
          )
          
          expect(my_location.phone_number.main).to be(false)
        end
      end
    end
  end

  describe "methods" do
    subject { build(:location, address: "18 North St, Binghamton, New York(NY), 13905", suite: "1800") }

    describe "#formatted_address" do
      # Here address_with_suite_number is tested indirectly
      it "should return address with suite num" do
        expect(subject.formatted_address).to eq("18 North St, 1800, Binghamton, New York(NY), 13905")
      end

      context "suite isn't provided" do
        it "should return address without suite num" do
          subject.suite = ""
          expect(subject.formatted_address).to eq("18 North St, Binghamton, New York(NY), 13905")
        end
      end
    end

    describe "#link_to_google_maps" do
      it "should return link to google maps with address appended" do
        expect(subject.link_to_google_maps).to eq("https://www.google.com/maps/search/18 North St, Binghamton, New York(NY), 13905")
      end
    end
  end
end
