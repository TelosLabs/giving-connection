# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchTerm, type: :model do
  describe ".normalize" do
    it "folds case and collapses surrounding and repeated whitespace" do
      expect(described_class.normalize("  Food   Pantry ")).to eq("food pantry")
    end

    it "returns nil for anything that isn't a term" do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize("   ")).to be_nil
    end

    it "truncates to the column's length so an oversized paste can't fail the insert" do
      expect(described_class.normalize("a" * 500).length).to eq(described_class::MAX_KEYWORD_LENGTH)
    end
  end

  describe ".top" do
    it "counts variants of the same term together, most searched first" do
      create(:search_term, keyword: "Food Pantry")
      create(:search_term, keyword: "food pantry")
      create(:search_term, keyword: "legal aid")

      expect(described_class.top).to eq({"food pantry" => 2, "legal aid" => 1})
    end

    it "ignores terms searched outside the window" do
      create(:search_term, keyword: "food pantry", created_at: 2.months.ago)

      expect(described_class.top(since: 30.days.ago)).to be_empty
    end
  end

  describe ".top_fruitless" do
    it "returns only terms that found nothing — the report this table exists for" do
      create(:search_term, keyword: "food pantry", results_count: 4)
      create(:search_term, keyword: "rent assistance", results_count: 0)

      expect(described_class.top_fruitless).to eq({"rent assistance" => 1})
    end
  end
end
