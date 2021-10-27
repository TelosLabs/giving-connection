# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Beneficiary, type: :model do
  context 'Beneficiary model validation test' do
    subject { create(:beneficiary) }

    it 'ensures beneficiary can be created' do
      expect(subject).to be_valid
    end
  end
end

