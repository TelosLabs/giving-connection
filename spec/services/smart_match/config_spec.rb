# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::Config do
  describe ".matching_rules" do
    subject(:rules) { described_class.matching_rules }

    it "returns a hash" do
      expect(rules).to be_a(Hash)
    end

    it "contains scoring weights" do
      expect(rules.dig("scoring", "weights")).to include(
        "embedding_similarity", "attribute_bonus", "distance"
      )
    end

    it "contains attribute weights" do
      expect(rules["attribute_weights"]).to include(
        "cause_match", "beneficiary_match", "scope_match", "service_match"
      )
    end

    it "contains radius_by_travel_bucket" do
      expect(rules["radius_by_travel_bucket"]).to be_a(Hash)
    end

    it "is memoized" do
      expect(described_class.matching_rules).to be(described_class.matching_rules)
    end
  end

  describe ".city_centroids" do
    subject(:centroids) { described_class.city_centroids }

    it "returns a hash" do
      expect(centroids).to be_a(Hash)
    end

    it "contains state-keyed entries" do
      expect(centroids.keys).to all(match(/\A[A-Z]{2}\z/))
    end

    it "contains latitude and longitude for each city" do
      centroids.each_value do |cities|
        cities.each_value do |coords|
          expect(coords).to include("latitude", "longitude")
        end
      end
    end

    it "is memoized" do
      expect(described_class.city_centroids).to be(described_class.city_centroids)
    end
  end
end
