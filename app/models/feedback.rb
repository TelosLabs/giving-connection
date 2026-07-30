# frozen_string_literal: true

require "csv"

class Feedback < ApplicationRecord
  belongs_to :user, optional: true

  # The categories the widget offers, as value => [label, icon]. Kept here so the
  # view options, the server-side validation and the admin notification email
  # share a single source of truth.
  CATEGORY_OPTIONS = {
    "search_results" => ["Search results", "feedback_cat_search.svg"],
    "accuracy_of_matches" => ["Accuracy of matches", "feedback_cat_accuracy.svg"],
    "ease_of_use" => ["Ease of use", "feedback_cat_ease.svg"],
    "speed_performance" => ["Speed / performance", "feedback_cat_speed.svg"],
    "filters_sorting" => ["Filters & sorting", "feedback_cat_filters.svg"],
    "location_map_results" => ["Location or map results", "feedback_cat_location.svg"],
    "something_didnt_work" => ["Something didn't work", "feedback_cat_issue.svg"],
    "other" => ["Other", nil]
  }.freeze

  CATEGORIES = CATEGORY_OPTIONS.keys.freeze

  # What each face on the rating row means.
  RATING_LABELS = {1 => "Mad", 2 => "Sad", 3 => "Meh", 4 => "Happy", 5 => "Love it"}.freeze

  validates :rating, presence: true, inclusion: {in: 1..5}
  # category is optional (the widget lets people submit without picking one),
  # but if present it must be one of the known values — the field is a hidden
  # input a direct POST could set to anything.
  validates :category, inclusion: {in: CATEGORIES}, allow_blank: true
  validates :comment, length: {maximum: 5_000}
  validates :context, :page_url, length: {maximum: 2_048}

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  CSV_HEADERS = ["Date", "Page URL", "Rating", "Type", "Comment", "Context", "Email", "Read"].freeze

  # Email is only available when the feedback was left by a logged-in user.
  def email
    user&.email
  end

  def rating_label
    RATING_LABELS[rating]
  end

  def category_label
    CATEGORY_OPTIONS.dig(category, 0)
  end

  def read?
    read_at.present?
  end

  # Boolean alias used by the admin dashboard's Field::Boolean.
  def read
    read?
  end

  def mark_as_read!
    update_column(:read_at, Time.current) unless read?
  end

  def mark_as_unread!
    update_column(:read_at, nil) if read?
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << CSV_HEADERS
      # find_each batches to keep memory flat on large exports. It orders by id
      # (:desc ≈ newest first, matching the admin index) rather than created_at.
      includes(:user).find_each(order: :desc) do |feedback|
        csv << [
          feedback.created_at&.iso8601,
          csv_safe(feedback.page_url),
          feedback.rating,
          csv_safe(feedback.category),
          csv_safe(feedback.comment),
          csv_safe(feedback.context),
          csv_safe(feedback.email),
          feedback.read? ? "Yes" : "No"
        ]
      end
    end
  end

  # Neutralize CSV formula/DDE injection: user-supplied text beginning with a
  # formula trigger (= + - @, or a leading tab/CR) is executed by Excel/Sheets
  # when the admin opens the export, so prefix it with an apostrophe.
  def self.csv_safe(value)
    text = value.to_s
    text.match?(/\A[=+\-@\t\r]/) ? "'#{text}" : text
  end
end
