# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do
  context 'PhoneNumber model validation test' do
    subject { create(:phone_number) }

    it 'ensures phone numbers can be created' do
      expect(subject).to be_valid
    end
  end
end
