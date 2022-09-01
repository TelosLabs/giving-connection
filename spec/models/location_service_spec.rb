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
require 'rails_helper'

RSpec.describe LocationService, type: :model do
  context 'LocationService model validation test' do
    subject { create(:location_service) }

    it 'ensures location_service can be created' do
      expect(subject).to be_valid
    end
  end
end
