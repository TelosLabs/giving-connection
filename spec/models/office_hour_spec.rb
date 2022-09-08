require 'rails_helper'

RSpec.describe OfficeHour, type: :model do
  describe "associations" do
    let(:a_location) { create(:location) }
    let(:an_office_hour) { create(:office_hour, location: a_location) }

    it 'should belong to a location' do
      expect(an_office_hour.location).to eql(a_location)
    end
  end

  describe "validations" do
    describe "day" do
      let(:office_hour_1) { build(:office_hour, day: nil) }
      let(:office_hour_2) { build(:office_hour, day: 7) }

      it 'should fail presence' do
        expect(office_hour_1.valid?).to be(false)
      end

      it 'should fail inclusion' do
        expect(office_hour_2.valid?).to be(false)
      end
    end

    describe "open_time" do
      let(:office_hour_1) { build(:office_hour, open_time: nil) }

      it 'should fail presence' do
        expect(office_hour_1.valid?).to be(false)
      end

      context 'closed' do
        let(:office_hour_2) { create(:office_hour, open_time: nil, closed: true) }
        
        it 'should not validate presence' do
          expect(OfficeHour.find(office_hour_2.id)).to eql(office_hour_2)
        end
      end

      context 'location doesn\'t offer service' do
        let(:location) { create(:location, offer_services: false) }
        let(:office_hour_3) { create(:office_hour, open_time: nil, location: location) }

        it 'should not validate presence' do
          expect(OfficeHour.find(office_hour_3.id)).to eql(office_hour_3)
        end
      end
    end

    describe "close_time" do
      let(:office_hour_1) { build(:office_hour, close_time: nil) }

      it 'should fail presence' do
        expect(office_hour_1.valid?).to be(false)
      end      
      
      context 'closed' do
        let(:office_hour_2) { create(:office_hour, close_time: nil, closed: true) }
        
        it 'should not validate presence' do
          expect(OfficeHour.find(office_hour_2.id)).to eql(office_hour_2)
        end
      end
      
      context 'location doesn\'t offer service' do 
        let(:location) { create(:location, offer_services: false) }
        let(:office_hour_3) { create(:office_hour, close_time: nil, location: location) }
        
        it 'should not validate presence' do
          expect(OfficeHour.find(office_hour_3.id)).to eql(office_hour_3)
        end
      end
    end
  end

  describe "methods" do
    describe "#day_name" do
      let(:office_hour) { build(:office_hour, day: 3) }

      it "should return wednesday" do
        expect(office_hour.day_name).to eql('Wednesday')
      end
    end

    describe "#formatted_open_time" do
      let(:office_hour) { build(:office_hour) }
      let(:current_day_hour_example) do
        today = Time.now
        open_time = office_hour.open_time
        Time.new(today.year, today.month, today.day, open_time.hour, open_time.min)
      end
      
      it "should match example" do
        expect(office_hour.formatted_open_time).to eql(current_day_hour_example)
      end
      
      context "open_time is nil" do
        let(:office_hour_closed) { build(:office_hour, open_time: nil) }

        it "should return nil" do
          expect(office_hour_closed.formatted_open_time).to eql(nil)
        end
      end
    end

    describe "#formatted_close_time" do
      let(:office_hour) { build(:office_hour) }
      let(:current_day_hour_example) do
        today = Time.now
        close_time = office_hour.close_time
        Time.new(today.year, today.month, today.day, close_time.hour, close_time.min)
      end
      
      it "should match example" do
        expect(office_hour.formatted_close_time).to eql(current_day_hour_example)
      end
      
      context "close_time is nil" do
        let(:office_hour_closed) { build(:office_hour, close_time: nil) }

        it "should return nil" do
          expect(office_hour_closed.formatted_close_time).to eql(nil)
        end
      end
    end
  end
end
