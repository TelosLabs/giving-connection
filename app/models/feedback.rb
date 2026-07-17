# frozen_string_literal: true

require "csv"

class Feedback < ApplicationRecord
  belongs_to :user, optional: true

  validates :rating, presence: true, inclusion: { in: 1..5 }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  CSV_HEADERS = ["Date", "Page URL", "Rating", "Type", "Comment", "Context", "Email", "Read"].freeze

  # Email is only available when the feedback was left by a logged-in user.
  def email
    user&.email
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
      includes(:user).order(created_at: :desc).find_each do |feedback|
        csv << [
          feedback.created_at&.iso8601,
          feedback.page_url,
          feedback.rating,
          feedback.category,
          feedback.comment,
          feedback.context,
          feedback.email,
          feedback.read? ? "Yes" : "No"
        ]
      end
    end
  end
end
