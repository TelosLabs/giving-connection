require 'rails_helper'

RSpec.describe AlertBeneficiary, type: :model do
  context 'AlertBeneficiary model validation test' do
    subject { create(:alert_beneficiary) }

    it 'ensures alert_beneficiary can be created' do
      expect(subject).to be_valid
    end
  end
end
