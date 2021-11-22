# frozen_string_literal: true

# == Schema Information
#
# Table name: beneficiary_groups
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe BeneficiaryGroup, type: :model do
  context 'Beneficiary model validation test' do
    subject { create(:beneficiary_group) }

    it 'ensures beneficiary can be created' do
      expect(subject).to be_valid
    end
  end
end
