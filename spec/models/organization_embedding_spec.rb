# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationEmbedding, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:organization) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:embedding) }
    it { is_expected.to validate_presence_of(:text_snapshot) }
  end

  describe "#stale?" do
    it "returns false when text_snapshot matches current org text" do
      org = create(:organization)
      current_text = SmartMatch::OrganizationTextBuilder.call(organization: org)
      embedding = create(:organization_embedding, organization: org, text_snapshot: current_text)

      expect(embedding.stale?).to be false
    end

    it "returns true when text_snapshot differs from current org text" do
      org = create(:organization)
      embedding = create(:organization_embedding, organization: org, text_snapshot: "outdated text")

      expect(embedding.stale?).to be true
    end
  end
end
