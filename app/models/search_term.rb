# frozen_string_literal: true

require "csv"

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

  CSV_HEADERS = ["Keyword", "Results Count", "City", "State", "Created At", "Filtered"].freeze

  # Generates a CSV for the given relation, preserving its order and filters.
  # Column order matches COLLECTION_ATTRIBUTES in SearchTermDashboard.
  def self.to_csv(scope)
    CSV.generate(headers: true) do |csv|
      csv << CSV_HEADERS
      scope.each do |search_term|
        csv << [
          csv_safe(search_term.keyword),
          search_term.results_count,
          csv_safe(search_term.city),
          csv_safe(search_term.state),
          search_term.created_at&.iso8601,
          search_term.filtered? ? "Yes" : "No"
        ]
      end
    end
  end

  # Neutralize CSV formula/DDE injection: keywords are visitor-supplied text
  # and could start with formula triggers (= + - @, tab, CR).
  def self.csv_safe(value)
    text = value.to_s
    text.match?(/\A[=+\-@\t\r]/) ? "'#{text}" : text
  end
end
