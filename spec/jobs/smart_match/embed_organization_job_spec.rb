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
      allow_any_instance_of(Organization).to receive(:smart_match_text).and_return(nil)

      expect {
        described_class.new.perform(org.id)
      }.not_to change(OrganizationEmbedding, :count)
    end

    it "enqueues on default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  # Debounce sentinel: a single nested-attribute save on Organization can
  # fire after_commit on Organization + N OrganizationCause + M
  # OrganizationBeneficiary + L Location, each enqueueing this job for the
  # same org. Without coalesce_for that's O(1 + N + M + L) duplicate jobs
  # against the single-worker Python service.
  describe ".coalesce_for" do
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Rails test env uses :null_store by default, which always returns
      # false from write(..., unless_exist: true) -- making the coalescer
      # think every enqueue is a duplicate. Swap in a real memory store for
      # these tests so we can exercise the actual debounce semantics.
      allow(Rails).to receive(:cache).and_return(memory_cache)
      ActiveJob::Base.queue_adapter = :test
    end

    # Helper: factory create(:organization) triggers after_commit
    # :schedule_embedding_update which itself calls coalesce_for. That sets
    # the cache key and enqueues a job BEFORE the test body runs. Each test
    # below creates its orgs first, then resets the cache + queue so the
    # assertion measures only the behavior of the explicit calls under test.
    def create_org_then_reset(*orgs_attrs)
      created = orgs_attrs.map { |attrs| create(:organization, **attrs) }
      memory_cache.clear
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      created
    end

    it "enqueues a job on first call within the debounce window" do
      (org,) = create_org_then_reset({})

      expect {
        described_class.coalesce_for(org.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    it "suppresses duplicate enqueues for the same org within the window" do
      (org,) = create_org_then_reset({})

      described_class.coalesce_for(org.id)

      expect {
        3.times { described_class.coalesce_for(org.id) }
      }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }
    end

    it "does not suppress enqueues for different organizations" do
      org, other = create_org_then_reset({}, {name: "Other Org"})

      described_class.coalesce_for(org.id)

      expect {
        described_class.coalesce_for(other.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    it "re-enqueues after the job clears its cache key on perform" do
      (org,) = create_org_then_reset({})

      described_class.coalesce_for(org.id)
      # Simulate the job starting: it deletes the key on first line of #perform.
      Rails.cache.delete("smart_match:embed_org:scheduled:#{org.id}")

      expect {
        described_class.coalesce_for(org.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end
  end
end
