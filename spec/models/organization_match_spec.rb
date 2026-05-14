# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationMatch, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:quiz_submission) }
    it { is_expected.to belong_to(:organization) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:score) }
    it { is_expected.to validate_presence_of(:rank) }
  end

  describe "score_breakdown" do
    it "stores and retrieves breakdown hash" do
      match = create(:organization_match, score_breakdown: {
        dense_similarity: 0.90,
        attribute_bonus: 0.75,
        distance_score: 0.80
      })

      breakdown = match.reload.score_breakdown
      expect(breakdown["dense_similarity"]).to eq(0.90)
      expect(breakdown["attribute_bonus"]).to eq(0.75)
      expect(breakdown["distance_score"]).to eq(0.80)
    end
  end
end
