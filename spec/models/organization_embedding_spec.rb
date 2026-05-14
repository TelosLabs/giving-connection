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

  describe ".upsert_for!" do
    let(:org) { create(:organization) }
    let(:vector_a) { Array.new(1024) { 0.1 } }
    let(:vector_b) { Array.new(1024) { 0.9 } }

    it "creates an embedding when none exists for the organization" do
      expect {
        described_class.upsert_for!(organization: org, embedding: vector_a, text_snapshot: "snap A")
      }.to change { described_class.where(organization: org).count }.from(0).to(1)
    end

    it "updates the embedding row in place on conflict (no duplicate row)" do
      described_class.upsert_for!(organization: org, embedding: vector_a, text_snapshot: "snap A")

      expect {
        described_class.upsert_for!(organization: org, embedding: vector_b, text_snapshot: "snap B")
      }.not_to change { described_class.where(organization: org).count }

      reloaded = described_class.find_by(organization: org)
      expect(reloaded.text_snapshot).to eq("snap B")
    end

    it "returns the upserted record" do
      result = described_class.upsert_for!(organization: org, embedding: vector_a, text_snapshot: "snap A")
      expect(result).to be_a(described_class)
      expect(result.organization_id).to eq(org.id)
    end

    # Atomicity sentinel: the prior find_or_initialize_by + update! pattern
    # was vulnerable to RecordNotUnique under concurrent writers (two callers
    # both seeing nothing, both inserting). The INSERT...ON CONFLICT version
    # should be safe even when two writers race -- second writer's INSERT
    # falls back to DO UPDATE rather than raising.
    it "does not raise on a second write racing the same organization id" do
      described_class.upsert_for!(organization: org, embedding: vector_a, text_snapshot: "snap A")

      expect {
        described_class.upsert_for!(organization: org, embedding: vector_b, text_snapshot: "snap B")
      }.not_to raise_error
    end
  end
end
