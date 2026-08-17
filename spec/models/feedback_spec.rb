# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe Feedback, type: :model do
  describe "validations" do
    it "requires a rating" do
      feedback = build(:feedback, rating: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:rating]).to be_present
    end

    it "accepts ratings within 1..5" do
      (1..5).each do |rating|
        expect(build(:feedback, rating: rating)).to be_valid
      end
    end

    it "rejects ratings outside 1..5" do
      [0, 6, -1].each do |rating|
        expect(build(:feedback, rating: rating)).not_to be_valid
      end
    end

    it "accepts a blank category" do
      expect(build(:feedback, category: nil)).to be_valid
      expect(build(:feedback, category: "")).to be_valid
    end

    it "accepts a known category and rejects an unknown one" do
      expect(build(:feedback, category: Feedback::CATEGORIES.first)).to be_valid
      expect(build(:feedback, category: "not_a_real_category")).not_to be_valid
    end

    it "rejects an over-long comment" do
      expect(build(:feedback, comment: "a" * 5_001)).not_to be_valid
      expect(build(:feedback, comment: "a" * 5_000)).to be_valid
    end

    it "accepts a blank page_url" do
      expect(build(:feedback, page_url: nil)).to be_valid
      expect(build(:feedback, page_url: "")).to be_valid
    end

    it "rejects a page_url that is not an http(s) URL" do
      ["javascript:alert(1)", "data:text/html,<script>", "/relative/path", "example.com"].each do |url|
        expect(build(:feedback, page_url: url)).not_to be_valid
      end
    end
  end

  describe "RATING_OPTIONS" do
    it "backs RATING_LABELS so the labels and faces cannot drift" do
      expect(Feedback::RATING_LABELS.keys).to eq(Feedback::RATING_OPTIONS.keys)
      expect(Feedback::RATING_LABELS[5]).to eq("Love it")
      expect(Feedback::RATING_OPTIONS[5].last).to eq("feedback_face_5_love.svg")
    end
  end

  describe "scopes" do
    let!(:unread) { create(:feedback, read_at: nil) }
    let!(:read) { create(:feedback, read_at: Time.current) }

    it ".unread returns only feedback without a read_at" do
      expect(Feedback.unread).to contain_exactly(unread)
    end

    it ".read returns only feedback with a read_at" do
      expect(Feedback.read).to contain_exactly(read)
    end
  end

  describe "read state" do
    it "#read? and #read reflect read_at presence" do
      feedback = build(:feedback, read_at: nil)
      expect(feedback.read?).to be(false)
      expect(feedback.read).to be(false)
      feedback.read_at = Time.current
      expect(feedback.read?).to be(true)
      expect(feedback.read).to be(true)
    end

    it "#mark_as_read! sets read_at and is idempotent" do
      feedback = create(:feedback, read_at: nil)
      feedback.mark_as_read!
      first = feedback.reload.read_at
      expect(first).to be_present

      feedback.mark_as_read!
      expect(feedback.reload.read_at).to eq(first)
    end

    it "#mark_as_unread! clears read_at" do
      feedback = create(:feedback, read_at: Time.current)
      feedback.mark_as_unread!
      expect(feedback.reload.read_at).to be_nil
    end
  end

  describe "#email" do
    it "returns the associated user's email or nil when anonymous" do
      user = create(:user)
      expect(create(:feedback, user: user).email).to eq(user.email)
      expect(create(:feedback, user: nil).email).to be_nil
    end
  end

  describe ".to_csv" do
    it "renders the header row and one row per feedback" do
      create(:feedback, rating: 5)
      rows = CSV.parse(described_class.to_csv, headers: true)
      expect(rows.headers).to eq(Feedback::CSV_HEADERS)
      expect(rows.size).to eq(1)
    end

    it "orders newest first" do
      older = create(:feedback, comment: "older")
      newer = create(:feedback, comment: "newer")
      rows = CSV.parse(described_class.to_csv, headers: true)
      expect(rows.pluck("Comment").first(2)).to eq([newer.comment, older.comment])
      expect(newer.id).to be > older.id
    end

    it "neutralizes CSV/formula-injection payloads in user text" do
      create(:feedback, comment: "=HYPERLINK(\"http://evil\")")
      rows = CSV.parse(described_class.to_csv, headers: true)
      expect(rows.first["Comment"]).to start_with("'=")
    end

    it "leaves ordinary text untouched" do
      create(:feedback, comment: "totally normal comment")
      rows = CSV.parse(described_class.to_csv, headers: true)
      expect(rows.first["Comment"]).to eq("totally normal comment")
    end
  end
end
