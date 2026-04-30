# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::EmbedOrganizationJob, type: :job do
  let(:vector) { Array.new(1024) { 0.1 } }

  describe "#perform" do
    it "creates an organization embedding" do
      org = create(:organization)
      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)

      expect {
        described_class.new.perform(org.id)
      }.to change(OrganizationEmbedding, :count).by(1)
    end

    it "updates existing embedding" do
      org = create(:organization)
      create(:organization_embedding, organization: org, text_snapshot: "old text")
      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)

      described_class.new.perform(org.id)

      embedding = org.reload.organization_embedding
      expect(embedding.text_snapshot).not_to eq("old text")
    end

    it "handles missing organization gracefully" do
      expect {
        described_class.new.perform(-1)
      }.not_to raise_error
    end

    it "skips organizations with no embeddable text" do
      org = create(:organization)
      allow(SmartMatch::OrganizationTextBuilder).to receive(:call).and_return(nil)

      expect {
        described_class.new.perform(org.id)
      }.not_to change(OrganizationEmbedding, :count)
    end

    it "enqueues on default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
