# frozen_string_literal: true

require "rails_helper"

# How much of the ranked pool the results page reveals.
#
# The rule is "the whole top tier, then more on request" rather than a fixed
# count: someone comparing nonprofits wants every organization we call a great
# fit, and the old fixed three made a 40-match pool look like a 3-match one.
RSpec.describe SmartMatch::ResultsPage do
  let(:submission) { create(:quiz_submission) }

  # Raw scores, not displayed percentages. display_calibration maps 0.25 -> 52%
  # and 0.80 -> 95%, so 0.75 displays as 91% (great, >= 75) and 0.45 as 68%
  # (good, >= 50). The first example guards those assumptions.
  def great = 0.75

  def good = 0.45

  def create_matches(scores)
    SmartMatchMatchRows.insert(submission: submission, scores: scores)
  end

  def page_for(page = 1)
    described_class.call(matches: submission.organization_matches, page: page)
  end

  # If the calibration knobs move, fail here rather than silently testing a
  # single tier in every example below.
  it "uses scores that land in the tiers it claims" do
    expect(OrganizationMatch.tier_for(great)).to eq(:great)
    expect(OrganizationMatch.tier_for(good)).to eq(:good)
  end

  it "shows every match in the top tier when that tier is deep enough" do
    create_matches([great] * 11 + [good] * 20)

    page = page_for

    expect(page.shown).to eq(11)
    expect(page.matches.map(&:rank)).to eq((1..11).to_a)
  end

  # The fallback: two great matches is not a page, so the next tier joins in.
  it "reaches into the next tier when the top one is too thin" do
    create_matches([great] * 2 + [good] * 9)

    expect(page_for.shown).to eq(11)
  end

  it "caps the fallback at the page size rather than showing every tier" do
    create_matches([great] * 2 + [good] * 30)

    expect(page_for.shown).to eq(20)
  end

  it "caps a huge top tier at the page size" do
    create_matches([great] * 45)

    page = page_for

    expect(page.shown).to eq(20)
    expect(page.next_page).to eq(2)
    expect(page.next_batch_size).to eq(20)
  end

  it "adds a page size worth on each step" do
    create_matches([great] * 45)

    expect(page_for(2).shown).to eq(40)
    expect(page_for(3).shown).to eq(45)
  end

  it "runs out rather than past the end of the pool" do
    create_matches([great] * 45)

    page = page_for(3)

    expect(page).not_to be_more
    expect(page.next_page).to be_nil
    expect(page.remaining).to eq(0)
  end

  it "promises only what is left when the last batch is short" do
    create_matches([great] * 25)

    expect(page_for.next_batch_size).to eq(5)
  end

  it "shows everything when the whole pool is smaller than the minimum" do
    create_matches([great, good])

    page = page_for

    expect(page.shown).to eq(2)
    expect(page).not_to be_more
  end

  it "handles a submission with no matches" do
    page = page_for

    expect(page.shown).to eq(0)
    expect(page.matches).to be_empty
    expect(page).not_to be_more
  end

  # The page number arrives in a query string, so it has to survive nonsense.
  it "treats a junk or out-of-range page as the first one" do
    create_matches([great] * 8)

    expect(page_for("nonsense").shown).to eq(8)
    expect(page_for(0).shown).to eq(8)
    expect(page_for(-3).shown).to eq(8)
  end
end
