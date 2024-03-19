require "rails_helper"

RSpec.describe OrganizationBeneficiary, type: :model do
  describe "associations" do
    subject { create(:organization_beneficiary) }

    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:beneficiary_subcategory) }
  end
end
