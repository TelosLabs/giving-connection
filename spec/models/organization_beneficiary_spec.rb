require "rails_helper"

RSpec.describe OrganizationBeneficiary, type: :model do
  describe "associations" do
    subject { create(:organization_beneficiary) }

    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:beneficiary_subcategory) }
  end

  describe "smart match embedding sync" do
    it "enqueues an org embedding refresh on create" do
      org = create(:organization)
      allow(SmartMatch::EmbedOrganizationJob).to receive(:coalesce_for)

      create(:organization_beneficiary, organization: org)

      expect(SmartMatch::EmbedOrganizationJob).to have_received(:coalesce_for).with(org.id)
    end

    it "enqueues an org embedding refresh on destroy" do
      org = create(:organization)
      organization_beneficiary = create(:organization_beneficiary, organization: org)
      allow(SmartMatch::EmbedOrganizationJob).to receive(:coalesce_for)

      organization_beneficiary.destroy

      expect(SmartMatch::EmbedOrganizationJob).to have_received(:coalesce_for).with(org.id)
    end
  end
end
