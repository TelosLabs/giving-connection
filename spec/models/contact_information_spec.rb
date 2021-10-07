# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactInformation, type: :model do
  context 'ContactInformation model validation test' do
    subject { create(:contact_information) }

    it 'ensures contact information can be created' do
      expect(subject).to be_valid
    end
  end
end
