require 'rails_helper'

RSpec.describe OrganizationBeneficiary, type: :model do
  describe "associations" do
    subject { create(:organization_beneficiary) }

    it { should belong_to(:organization) }
    it { should belong_to(:beneficiary_subcategory) }
  end
end
