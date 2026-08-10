# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::CriteriaSummary do
  def match_with(*criteria)
    build(:organization_match, score_breakdown: {"criteria" => criteria})
  end

  def criterion(question, answer, status)
    {"question" => question, "answer" => answer, "status" => status}
  end

  def grouped_criterion(status, matched, selected)
    {"question" => "services", "answer" => nil, "status" => status,
     "grouped" => true, "matched_count" => matched, "selected_count" => selected}
  end

  def summary_for(matches)
    described_class.call(matches: matches).to_h { |c| [[c.question, c.answer], c] }
  end

  it "returns nothing when there are no matches" do
    expect(described_class.call(matches: [])).to eq([])
  end

  it "marks a criterion met by every match as met" do
    matches = [
      match_with(criterion("prefs", "wheelchair_accessible", "met")),
      match_with(criterion("prefs", "wheelchair_accessible", "met"))
    ]

    entry = summary_for(matches)[["prefs", "wheelchair_accessible"]]

    expect(entry.status).to eq("met")
    expect(entry.met_count).to eq(2)
    expect(entry.total).to eq(2)
  end

  # The distinction that makes the panel worth showing: "one of your three
  # matches is accessible" is materially different from "all of them are".
  it "marks a criterion met by only some matches as partial" do
    matches = [
      match_with(criterion("prefs", "wheelchair_accessible", "met")),
      match_with(criterion("prefs", "wheelchair_accessible", "unmet")),
      match_with(criterion("prefs", "wheelchair_accessible", "unmet"))
    ]

    entry = summary_for(matches)[["prefs", "wheelchair_accessible"]]

    expect(entry.status).to eq("partial")
    expect(entry.met_count).to eq(1)
    expect(entry.total).to eq(3)
  end

  it "marks a criterion no match meets as unmet" do
    matches = [
      match_with(criterion("prefs", "no_id_required", "unmet")),
      match_with(criterion("prefs", "no_id_required", "unmet"))
    ]

    expect(summary_for(matches)[["prefs", "no_id_required"]].status).to eq("unmet")
  end

  # "Nobody has told us" must not be reported as "nobody offers it" -- the user
  # may still want to call and ask.
  it "marks a criterion no match has answered as unknown" do
    matches = [
      match_with(criterion("prefs", "free_sliding_scale", "unknown")),
      match_with(criterion("prefs", "free_sliding_scale", "unknown"))
    ]

    entry = summary_for(matches)[["prefs", "free_sliding_scale"]]

    expect(entry.status).to eq("unknown")
    expect(entry).to be_unknown
  end

  it "prefers unmet over unknown when at least one match gave a definite no" do
    matches = [
      match_with(criterion("prefs", "free_sliding_scale", "unknown")),
      match_with(criterion("prefs", "free_sliding_scale", "unmet"))
    ]

    expect(summary_for(matches)[["prefs", "free_sliding_scale"]].status).to eq("unmet")
  end

  it "keeps the order criteria were recorded in" do
    matches = [
      match_with(
        criterion("causes", "Mental Health", "met"),
        criterion("self_description", "senior", "unmet"),
        criterion("prefs", "wheelchair_accessible", "unknown")
      )
    ]

    expect(described_class.call(matches: matches).map(&:answer))
      .to eq(["Mental Health", "senior", "wheelchair_accessible"])
  end

  # Personal Details still score, but showing them would imply results were
  # filtered by the user's race or gender, which is not what happens.
  describe "personal details" do
    it "omits age, gender and race from the panel" do
      matches = [
        match_with(
          criterion("causes", "Health", "met"),
          criterion("age_range", "19_24", "unmet"),
          criterion("gender_identity", "non_binary", "unmet"),
          criterion("race_ethnicity", "black_african_american", "met")
        )
      ]

      expect(described_class.call(matches: matches).map(&:question)).to eq(["causes"])
    end

    it "returns nothing when personal details were the only criteria" do
      matches = [match_with(criterion("age_range", "over_65", "met"))]

      expect(described_class.call(matches: matches)).to be_empty
    end
  end

  # The headline used to count only fully-met criteria, which read "1 of 12"
  # even when most were partly met and made the engine look broken.
  describe "counting matches for the headline" do
    it "counts a partial criterion as matched" do
      matches = [
        match_with(criterion("causes", "Health", "met")),
        match_with(criterion("causes", "Health", "unmet"))
      ]

      entry = described_class.call(matches: matches).first

      expect(entry.status).to eq("partial")
      expect(entry).to be_matched
      expect(entry).not_to be_all_met
    end

    it "does not count an unmet or unknown criterion as matched" do
      matches = [
        match_with(criterion("prefs", "no_id_required", "unmet"),
          criterion("prefs", "multilingual", "unknown"))
      ]

      expect(described_class.call(matches: matches).count(&:matched?)).to eq(0)
    end
  end

  describe "grouped (proportional) criteria" do
    it "carries how many of the user's selections were found" do
      matches = [
        match_with(grouped_criterion("partial", 1, 4)),
        match_with(grouped_criterion("partial", 3, 4))
      ]

      entry = described_class.call(matches: matches).first

      expect(entry).to be_detail
      expect(entry.selected_count).to eq(4)
      # Best showing across the shown organizations.
      expect(entry.matched_count).to eq(3)
      expect(entry.status).to eq("partial")
    end

    it "reports a fully-covered selection as met" do
      matches = [match_with(grouped_criterion("met", 2, 2))]

      expect(described_class.call(matches: matches).first.status).to eq("met")
    end
  end

  # Matches persisted before criteria shipped have no such key.
  it "tolerates matches with no criteria recorded" do
    matches = [build(:organization_match, score_breakdown: {}), match_with(criterion("causes", "Health", "met"))]

    expect(described_class.call(matches: matches).map(&:answer)).to eq(["Health"])
  end
end
