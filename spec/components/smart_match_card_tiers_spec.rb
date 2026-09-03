# frozen_string_literal: true

require "rails_helper"

# The card's tier lookups are three parallel hashes that must stay keyed the
# same way as OrganizationMatch::TIERS. Nothing couples them at load time: they
# are separate literals in separate files, and `fetch` only complains at render
# time, on whichever tier happens to be missing -- so adding or renaming a tier
# ships a card that raises for some scores and works for others.
#
# This is the coupling, asserted once.
RSpec.describe SmartMatchCard::Component do
  let(:tiers) { OrganizationMatch::TIERS.keys }

  {
    "TIER_LABELS" => :label,
    "TIER_LABEL_COLORS" => :label_color,
    "TIER_CIRCLE_COLORS" => :circle_color
  }.each_key do |constant|
    it "#{constant} covers exactly the tiers OrganizationMatch defines" do
      expect(described_class.const_get(constant).keys).to match_array(tiers)
    end
  end

  it "resolves a label, a label colour and a ring colour for every tier" do
    tiers.each do |tier|
      match = instance_double(OrganizationMatch, tier: tier, display_percentage: 60)
      card = described_class.new(organization: build(:organization), match: match)

      expect { card.match_label }.not_to raise_error
      expect { card.match_label_color }.not_to raise_error
      expect { card.circle_color }.not_to raise_error
    end
  end
end
