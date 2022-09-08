require 'rails_helper'

RSpec.describe BeneficiarySubcategory, type: :model do
  describe "associations" do
    let(:beneficiary_group) { create(:beneficiary_group) }
    let(:beneficiary_subcategory) { create(:beneficiary_subcategory, beneficiary_group: beneficiary_group) }

    it "should belong to a beneficiary group" do
      expect(beneficiary_subcategory.beneficiary_group).to equal(beneficiary_group)
    end
  end
end
