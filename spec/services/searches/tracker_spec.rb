# frozen_string_literal: true

require "rails_helper"

RSpec.describe Searches::Tracker do
  def track(**overrides)
    described_class.call(keyword: "food pantry", results_count: 3, **overrides)
  end

  it "records the search" do
    expect { track(origin: "home", city: "Nashville", state: "Tennessee") }
      .to change(SearchTerm, :count).by(1)

    term = SearchTerm.last
    expect(term).to have_attributes(
      keyword: "food pantry",
      normalized_keyword: "food pantry",
      results_count: 3,
      origin: "home",
      city: "Nashville",
      state: "Tennessee",
      filtered: false
    )
  end

  it "records searches that found nothing, which is the point of storing this at all" do
    track(results_count: 0)

    expect(SearchTerm.last.results_count).to eq(0)
  end

  context "when the keyword is not a real search" do
    it "records nothing for a blank keyword" do
      expect { track(keyword: "  ") }.not_to change(SearchTerm, :count)
      expect { track(keyword: nil) }.not_to change(SearchTerm, :count)
    end
  end

  context "when the search is a refinement of the previous one" do
    # Every filter pill, distance button and city change re-submits the form with
    # the keyword unchanged. Counting those would inflate one search into five.
    it "records nothing when the keyword is unchanged" do
      expect { track(previous_keyword: "food pantry") }.not_to change(SearchTerm, :count)
    end

    it "ignores case and whitespace when deciding that" do
      expect { track(keyword: "Food  Pantry", previous_keyword: "food pantry") }
        .not_to change(SearchTerm, :count)
    end

    it "records a genuinely different keyword" do
      expect { track(keyword: "legal aid", previous_keyword: "food pantry") }
        .to change(SearchTerm, :count).by(1)
    end
  end

  describe "origin" do
    it "drops an origin that isn't one of ours rather than storing arbitrary input" do
      track(origin: "<script>alert(1)</script>")

      expect(SearchTerm.last.origin).to be_nil
    end
  end

  it "never lets an analytics failure break the search request" do
    allow(SearchTerm).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, "boom")

    expect { expect(track).to be_nil }.not_to raise_error
  end
end
