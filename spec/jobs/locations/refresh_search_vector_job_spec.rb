# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::RefreshSearchVectorJob, type: :job do
  describe "#perform" do
    it "refreshes search_vector for every location belonging to the organization" do
      org = create(:organization, name: "Refresh Me #{SecureRandom.hex(4)}")
      location = org.locations.first
      expect(location.search_vector).to be_nil

      described_class.new.perform(org.id)

      expect(location.reload.search_vector).to be_present
    end

    it "handles an organization with no locations gracefully" do
      expect {
        described_class.new.perform(-1)
      }.not_to raise_error
    end

    it "enqueues on default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  # Debounce sentinel: a single nested-attribute save on Organization can fire
  # after_commit on Organization + N OrganizationCause + Tag + SocialMedia +
  # Location, each enqueueing this job for the same org. Without
  # coalesce_for_organization that's O(N) duplicate reindex jobs for one edit.
  describe ".coalesce_for_organization" do
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Rails test env uses :null_store by default, which always returns
      # false from write(..., unless_exist: true) -- making the coalescer
      # think every enqueue is a duplicate. Swap in a real memory store for
      # these tests so we can exercise the actual debounce semantics.
      allow(Rails).to receive(:cache).and_return(memory_cache)
      ActiveJob::Base.queue_adapter = :test
    end

    # Helper: factory create(:organization) triggers after_commit callbacks
    # that themselves call coalesce_for_organization, setting the cache key
    # and enqueueing a job BEFORE the test body runs. Each test below creates
    # its orgs first, then resets the cache + queue so the assertion measures
    # only the behavior of the explicit calls under test.
    def create_org_then_reset(*orgs_attrs)
      created = orgs_attrs.map { |attrs| create(:organization, **attrs) }
      memory_cache.clear
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      created
    end

    it "enqueues a job on first call within the debounce window" do
      (org,) = create_org_then_reset({})

      expect {
        described_class.coalesce_for_organization(org.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    it "suppresses duplicate enqueues for the same organization within the window" do
      (org,) = create_org_then_reset({})

      described_class.coalesce_for_organization(org.id)

      expect {
        3.times { described_class.coalesce_for_organization(org.id) }
      }.not_to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }
    end

    it "does not suppress enqueues for different organizations" do
      org, other = create_org_then_reset({}, {name: "Other Org #{SecureRandom.hex(4)}"})

      described_class.coalesce_for_organization(org.id)

      expect {
        described_class.coalesce_for_organization(other.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    it "re-enqueues after the job clears its cache key on perform" do
      (org,) = create_org_then_reset({})

      described_class.coalesce_for_organization(org.id)
      # Simulate the job starting: it deletes the key on the first line of #perform.
      Rails.cache.delete("locations:refresh_search_vector:scheduled:#{org.id}")

      expect {
        described_class.coalesce_for_organization(org.id)
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end
  end
end
