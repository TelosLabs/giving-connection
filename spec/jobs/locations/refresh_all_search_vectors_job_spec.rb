# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::RefreshAllSearchVectorsJob, type: :job do
  describe "#perform" do
    it "populates search_vector for every location, batched" do
      org = create(:organization, name: "Backfill Me #{SecureRandom.hex(4)}")
      location = org.locations.first
      expect(location.search_vector).to be_nil

      stub_const("#{described_class}::BATCH_SIZE", 1)

      described_class.new.perform

      expect(location.reload.search_vector).to be_present
    end

    it "recomputes an already-populated search_vector rather than skipping it" do
      org = create(:organization, name: "Stale Name #{SecureRandom.hex(4)}")
      location = org.locations.first
      Location.refresh_search_vector!([location.id])
      expect(Location.search_by_keyword("Stale")).to include(location.reload)

      org.update_columns(name: "Renamed #{SecureRandom.hex(4)}")
      described_class.new.perform
      location.reload

      expect(Location.search_by_keyword("Stale")).not_to include(location)
      expect(Location.search_by_keyword("Renamed")).to include(location)
    end
  end
end
