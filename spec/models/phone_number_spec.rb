# frozen_string_literal: true

# == Schema Information
#
# Table name: phone_numbers
#
#  id          :bigint           not null, primary key
#  number      :string
#  main        :boolean
#  location_id :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do
  context 'PhoneNumber model validation test' do
    subject { create(:phone_number) }

    it 'ensures phone_number can be created' do
      expect(subject).to be_valid
    end
  end
end
