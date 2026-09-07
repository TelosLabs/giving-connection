# frozen_string_literal: true

class OrganizationMatch < ApplicationRecord
  belongs_to :quiz_submission
  belongs_to :organization

  validates :score, presence: true
  validates :rank, presence: true

  # Match tiers, best first, keyed by the lowest DISPLAYED percentage that
  # earns each one.
  #
  # Keyed on the displayed percentage rather than the raw score on purpose: the
  # results page groups by tier and the card prints the tier's label, and those
  # two must never disagree. SmartMatch::ResultsPage walks this hash in order
  # when deciding how far down the ranking the first page has to reach.
  TIERS = {great: 75, good: 50, match: 0}.freeze

  def tier
    self.class.tier_for(score)
  end

  def display_percentage
    self.class.display_percentage_for(score)
  end

  class << self
    # Tier from a bare score, so callers that only need the grouping can work
    # from plucked scores instead of instantiating every match (ResultsPage
    # decides the page boundary before loading any cards).
    def tier_for(score)
      percentage = display_percentage_for(score)
      TIERS.find { |_tier, floor| percentage >= floor }.first
    end

    def display_percentage_for(score)
      (calibrated_fraction(score) * 100).round
    end

    # The displayed match fraction (0.0-1.0) after presentation-only
    # calibration. Raw scores are dominated by compressed embedding similarity;
    # the linear rescale defined in matching_rules.yml#display_calibration
    # stretches them onto a more intuitive band. It is monotonic, so ranking --
    # and therefore tier ORDER -- is unaffected.
    def calibrated_fraction(score)
      raw = score.to_f.clamp(0.0, 1.0)
      cfg = SmartMatch::MATCHING_RULES["display_calibration"]
      return raw unless cfg

      floor = cfg["input_floor"].to_f
      ceiling = cfg["input_ceiling"].to_f
      return raw if ceiling <= floor

      min_fraction = cfg["min_percentage"].to_f / 100.0
      max_fraction = cfg["max_percentage"].to_f / 100.0
      t = ((raw - floor) / (ceiling - floor)).clamp(0.0, 1.0)
      (min_fraction + t * (max_fraction - min_fraction)).clamp(0.0, 1.0)
    end
  end
end
