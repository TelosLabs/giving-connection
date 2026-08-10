# frozen_string_literal: true

require "rails_helper"

# Per-card "why this match" chips.
#
# Answers are OR'd, not AND'd -- every result satisfies some subset of what the
# user asked for, so naming that subset is what tells one card apart from the
# next. Misses stay in the aggregate panel; repeating them per card would
# triple the noise without adding information.
RSpec.describe SmartMatchCard::Component, type: :component do
  def card_for(criteria, rule_matches: [])
    organization = create(:organization)
    match = build(:organization_match,
      organization: organization,
      score: 0.5,
      score_breakdown: {"criteria" => criteria, "rule_matches" => rule_matches})

    described_class.new(organization: organization, match: match, user_type: "service_seeker")
  end

  def criterion(question, answer, status, **extra)
    {"question" => question, "answer" => answer, "status" => status}.merge(extra.transform_keys(&:to_s))
  end

  it "names the criteria this organization satisfies" do
    card = card_for([
      criterion("causes", "Mental Health", "met"),
      criterion("self_description", "senior", "met")
    ])

    expect(card.match_reasons).to contain_exactly("Mental Health", "Senior")
  end

  it "omits criteria the organization does not satisfy" do
    card = card_for([
      criterion("causes", "Mental Health", "met"),
      criterion("prefs", "wheelchair_accessible", "unmet"),
      criterion("prefs", "no_id_required", "unknown")
    ])

    expect(card.match_reasons).to eq(["Mental Health"])
  end

  it "never names age, gender or race" do
    card = card_for([
      criterion("causes", "Health", "met"),
      criterion("race_ethnicity", "hispanic_latino", "met"),
      criterion("gender_identity", "male", "met")
    ])

    expect(card.match_reasons).to eq(["Health"])
  end

  # Ordered by what actually moved the score, so the strongest reason leads
  # rather than whichever question came first in the quiz.
  it "leads with the highest-scoring reason" do
    card = card_for(
      [
        criterion("prefs", "lgbtqia_affirming", "met"),
        criterion("causes", "Mental Health", "met")
      ],
      rule_matches: [
        {"question" => "prefs", "answer" => "lgbtqia_affirming", "contribution" => 1.0},
        {"question" => "causes", "answer" => "Mental Health", "contribution" => 7.5}
      ]
    )

    expect(card.match_reasons.first).to eq("Mental Health")
  end

  # The overwhelm guard: a user who answered a lot must not get a wall of chips.
  it "caps the chips and counts the remainder" do
    card = card_for([
      criterion("causes", "Health", "met"),
      criterion("causes", "Mental Health", "met"),
      criterion("causes", "Seniors", "met"),
      criterion("causes", "Education", "met"),
      criterion("causes", "Employment", "met")
    ])

    expect(card.match_reasons.size).to eq(described_class::MAX_MATCH_REASONS)
    expect(card.hidden_match_reason_count).to eq(2)
  end

  it "reports no remainder when everything fits" do
    card = card_for([criterion("causes", "Health", "met")])

    expect(card.hidden_match_reason_count).to eq(0)
  end

  it "shows how much of a grouped selection was found" do
    card = card_for([
      criterion("services", nil, "partial", grouped: true, matched_count: 2, selected_count: 4)
    ])

    expect(card.match_reasons.first).to eq("Specific services you asked for (2/4)")
  end

  it "shows nothing for a match with no recorded criteria" do
    card = card_for([])

    expect(card.match_reasons).to be_empty
    expect(card.hidden_match_reason_count).to eq(0)
  end
end
