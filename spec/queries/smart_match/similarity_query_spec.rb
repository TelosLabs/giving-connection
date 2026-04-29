# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::SimilarityQuery do
  let(:embedding) { Array.new(1024) { rand(-1.0..1.0) } }
  let(:coordinates) { {latitude: 36.1627, longitude: -86.7816} }

  describe ".call" do
    it "returns results filtered by state" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: coordinates,
        radius_miles: 50
      )

      expect(results).to be_an(Array)
    end

    it "returns results with expected keys" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: coordinates,
        radius_miles: 50
      )

      expect(results).to be_an(Array)
      result = results.first
      expect(result).to include(:organization_embedding, :cosine_distance, :distance_miles)
    end

    it "falls back to state-wide results when no nearby results" do
      org = create(:organization)
      loc = org.locations.first
      loc.update_columns(address: "123 Main St, Nashville, TN 37201")
      create(:organization_embedding, organization: org)

      far_coordinates = {latitude: 0.0, longitude: 0.0}

      results = described_class.call(
        embedding: embedding,
        state: "TN",
        coordinates: far_coordinates,
        radius_miles: 5
      )

      expect(results).to be_an(Array)
    end
  end
end
