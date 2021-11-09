# frozen_string_literal: true

# == Schema Information
#
# Table name: services
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :text
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe Service, type: :model do
  context 'Service model validation test' do
    subject { create(:service) }

    it 'ensures service can be created' do
      expect(subject).to be_valid
    end
  end
end
