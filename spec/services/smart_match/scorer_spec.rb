# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::Scorer do
  let(:user_intent) do
    UserIntent.new(
      user_type: "volunteer",
      state: "TN",
      city: "Nashville",
      travel_bucket: "moderate",
      causes_selected: ["Education"]
    )
  end

  describe ".call" do
    it "scores and ranks candidates by total score descending" do
      org1 = create(:organization)
      org2 = create(:organization, name: "Second Org")
      oe1 = create(:organization_embedding, organization: org1)
      oe2 = create(:organization_embedding, organization: org2)

      candidates = [
        {organization_embedding: oe1, cosine_distance: 0.3, distance_miles: 5},
        {organization_embedding: oe2, cosine_distance: 0.1, distance_miles: 10}
      ]

      results = described_class.call(candidates: candidates, user_intent: user_intent)

      expect(results.first[:score]).to be >= results.last[:score]
    end

    it "returns score breakdown for each candidate" do
      org = create(:organization)
      oe = create(:organization_embedding, organization: org)

      candidates = [{organization_embedding: oe, cosine_distance: 0.2, distance_miles: 5}]
      results = described_class.call(candidates: candidates, user_intent: user_intent)

      breakdown = results.first[:score_breakdown]
      expect(breakdown).to include(:dense_similarity, :attribute_bonus, :distance_score)
    end

    it "calculates dense score as 1 - cosine_distance" do
      org = create(:organization)
      oe = create(:organization_embedding, organization: org)

      candidates = [{organization_embedding: oe, cosine_distance: 0.2, distance_miles: nil}]
      results = described_class.call(candidates: candidates, user_intent: user_intent)

      expect(results.first[:score_breakdown][:dense_similarity]).to eq(0.8)
    end

    it "gives full distance score for nil distance (state-wide fallback)" do
      org = create(:organization)
      oe = create(:organization_embedding, organization: org)

      candidates = [{organization_embedding: oe, cosine_distance: 0.5, distance_miles: nil}]
      results = described_class.call(candidates: candidates, user_intent: user_intent)

      expect(results.first[:score_breakdown][:distance_score]).to eq(1.0)
    end

    it "gives full distance score for distance <= 5 miles" do
      org = create(:organization)
      oe = create(:organization_embedding, organization: org)

      candidates = [{organization_embedding: oe, cosine_distance: 0.5, distance_miles: 3}]
      results = described_class.call(candidates: candidates, user_intent: user_intent)

      expect(results.first[:score_breakdown][:distance_score]).to eq(1.0)
    end

    it "reduces distance score for farther organizations" do
      org = create(:organization)
      oe = create(:organization_embedding, organization: org)

      candidates = [{organization_embedding: oe, cosine_distance: 0.5, distance_miles: 50}]
      results = described_class.call(candidates: candidates, user_intent: user_intent)

      expect(results.first[:score_breakdown][:distance_score]).to eq(0.5)
    end
  end
end
