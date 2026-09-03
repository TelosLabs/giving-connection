require "rails_helper"

RSpec.describe OrganizationCause, type: :model do
  subject { build(:organization_cause) }

  describe "Associations" do
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:cause) }
  end

  describe "smart match embedding sync" do
    it "enqueues an org embedding refresh on create" do
      org = create(:organization)
      allow(SmartMatch::EmbedOrganizationJob).to receive(:coalesce_for)

      create(:organization_cause, organization: org)

      expect(SmartMatch::EmbedOrganizationJob).to have_received(:coalesce_for).with(org.id)
    end

    it "enqueues an org embedding refresh on destroy" do
      org = create(:organization)
      organization_cause = create(:organization_cause, organization: org)
      allow(SmartMatch::EmbedOrganizationJob).to receive(:coalesce_for)

      organization_cause.destroy

      expect(SmartMatch::EmbedOrganizationJob).to have_received(:coalesce_for).with(org.id)
    end
  end
end
