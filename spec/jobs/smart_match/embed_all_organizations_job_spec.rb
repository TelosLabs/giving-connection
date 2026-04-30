# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::EmbedAllOrganizationsJob, type: :job do
  let(:vector) { Array.new(1024) { 0.1 } }

  describe "#perform" do
    it "creates embeddings for all active organizations" do
      org1 = create(:organization)
      org2 = create(:organization, name: "Second Org")

      allow(SmartMatch::OrganizationTextBuilder).to receive(:call).and_return("test embedding text")
      allow(SmartMatch::EmbeddingClient).to receive(:embed_batch) { |texts:| texts.map { vector } }

      described_class.new.perform

      expect(OrganizationEmbedding.where(organization: [org1, org2]).count).to eq(2)
    end

    it "skips organizations with nil text" do
      org = create(:organization)
      allow(SmartMatch::OrganizationTextBuilder).to receive(:call).and_return(nil)

      described_class.new.perform

      expect(OrganizationEmbedding.where(organization: org).count).to eq(0)
    end

    it "calls embed_batch instead of individual calls" do
      create(:organization)
      allow(SmartMatch::OrganizationTextBuilder).to receive(:call).and_return("test embedding text")
      allow(SmartMatch::EmbeddingClient).to receive(:embed_batch) { |texts:| texts.map { vector } }

      described_class.new.perform

      expect(SmartMatch::EmbeddingClient).to have_received(:embed_batch).at_least(:once)
    end

    it "enqueues on default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
