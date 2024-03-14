require "rails_helper"

RSpec.describe BeneficiarySubcategory, type: :model do
  describe "associations" do
    subject { create(:beneficiary_subcategory) }

    it { is_expected.to belong_to(:beneficiary_group) }
  end
end
