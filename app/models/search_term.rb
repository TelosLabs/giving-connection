# frozen_string_literal: true

# One row per keyword search a visitor actually performed.
#
# Filter refinements of an existing search are deliberately not recorded — see
# Searches::Tracker — so counts here answer "how many people searched for this",
# not "how many requests mentioned it".
class SearchTerm < ApplicationRecord
  MAX_KEYWORD_LENGTH = 255

  validates :keyword, presence: true
  validates :normalized_keyword, presence: true

  scope :created_since, ->(time) { where(created_at: time..) }
  scope :fruitless, -> { where(results_count: 0) }

  # The two reports this table exists for: what people look for, and what they
  # look for and don't find.
  def self.top(limit: 25, since: 30.days.ago)
    created_since(since)
      .group(:normalized_keyword)
      .order("count(normalized_keyword) desc")
      .limit(limit)
      .count
  end

  def self.top_fruitless(limit: 25, since: 30.days.ago)
    fruitless.top(limit: limit, since: since)
  end

  # Case and whitespace are noise in a top-terms report: "Food Pantry",
  # "food  pantry" and "food pantry " are all one term.
  def self.normalize(keyword)
    keyword.to_s.strip.squeeze(" ").downcase.first(MAX_KEYWORD_LENGTH).presence
  end
end
