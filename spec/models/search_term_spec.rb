# frozen_string_literal: true

require "rails_helper"
require "csv"

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

  describe ".to_csv" do
    it "generates a CSV with the correct headers" do
      rows = CSV.parse(described_class.to_csv(described_class.none))
      expect(rows.first).to eq(SearchTerm::CSV_HEADERS)
    end

    it "includes one row per record in the given scope with the correct column values" do
      term = create(:search_term, keyword: "food pantry", results_count: 3,
        city: "Nashville", state: "TN", filtered: false)
      rows = CSV.parse(described_class.to_csv(described_class.all), headers: true)

      expect(rows.length).to eq(1)
      expect(rows.first["Keyword"]).to eq("food pantry")
      expect(rows.first["Results Count"]).to eq("3")
      expect(rows.first["City"]).to eq("Nashville")
      expect(rows.first["State"]).to eq("TN")
      expect(rows.first["Filtered"]).to eq("No")
      expect(rows.first["Created At"]).to eq(term.created_at.strftime("%m/%d/%Y %-H:%M:%S"))
    end

    it "outputs Yes in the Filtered column for filtered terms" do
      create(:search_term, filtered: true)
      rows = CSV.parse(described_class.to_csv(described_class.all), headers: true)

      expect(rows.first["Filtered"]).to eq("Yes")
    end

    it "only exports records in the given scope" do
      create(:search_term, keyword: "food pantry")
      create(:search_term, keyword: "legal aid")

      csv = described_class.to_csv(described_class.where(keyword: "food pantry"))

      expect(csv).to include("food pantry")
      expect(csv).not_to include("legal aid")
    end

    it "preserves the ordering of the given scope" do
      create(:search_term, keyword: "older term", created_at: 2.days.ago)
      create(:search_term, keyword: "newer term")

      csv = described_class.to_csv(described_class.order(created_at: :desc))

      expect(csv.index("newer term")).to be < csv.index("older term")
    end
  end

  describe ".csv_safe" do
    it "returns normal text unchanged" do
      expect(described_class.csv_safe("food pantry")).to eq("food pantry")
    end

    it "handles nil by returning an empty string" do
      expect(described_class.csv_safe(nil)).to eq("")
    end

    it "prefixes formula-injection triggers with an apostrophe" do
      ["=CMD", "+CMD", "-CMD", "@CMD", "\tCMD", "\rCMD"].each do |dangerous|
        expect(described_class.csv_safe(dangerous)).to start_with("'"),
          "expected #{dangerous.inspect} to be escaped"
      end
    end

    it "leaves text that merely contains a trigger mid-string alone" do
      expect(described_class.csv_safe("a=b")).to eq("a=b")
    end
  end
end
