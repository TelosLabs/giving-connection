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

  # Tiers live on the model because two things consume them and must agree: the
  # card prints the tier's label, and SmartMatch::ResultsPage decides how far
  # down the ranking the first page reaches by counting tiers.
  describe ".tier_for" do
    it "reads the tier off the displayed percentage, not the raw score" do
      # 0.75 raw is well under the 75 great-match cutoff; calibrated it displays
      # as 91%. Comparing the raw score to the cutoff would call this "good".
      expect(described_class.display_percentage_for(0.75)).to be >= 75
      expect(described_class.tier_for(0.75)).to eq(:great)
    end

    it "puts a middling score in the good tier" do
      expect(described_class.tier_for(0.45)).to eq(:good)
    end

    it "clamps a score outside 0..1 rather than inventing a tier" do
      expect(described_class.tier_for(3.0)).to eq(:great)
      expect(described_class.tier_for(-1.0)).to eq(described_class.tier_for(0.0))
    end

    # Documents a live coupling rather than an intention: display_calibration
    # floors the displayed percentage at min_percentage (52), which sits ABOVE
    # the `match` tier's ceiling of 50 -- so no real score can land in the
    # lowest tier, and the salmon "Match" label is currently unreachable. If
    # this fails, the calibration floor moved and the lowest tier is now live:
    # check that the fallback in ResultsPage and the card label still read well.
    it "cannot reach the lowest tier while the calibration floor sits above it" do
      expect(described_class.tier_for(0.0)).not_to eq(:match)
    end
  end

  describe "#tier" do
    it "delegates to the class method for the record's own score" do
      match = build(:organization_match, score: 0.45)

      expect(match.tier).to eq(:good)
      expect(match.display_percentage).to eq(described_class.display_percentage_for(0.45))
    end
  end
end
