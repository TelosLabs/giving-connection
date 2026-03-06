# frozen_string_literal: true

class QuizSubmission < ApplicationRecord
  belongs_to :user, optional: true
  has_many :organization_matches, dependent: :destroy
  has_neighbors :embedding

  validates :session_id, presence: true
  validates :user_type, presence: true
  validates :embedding, presence: true
  validates :text_snapshot, presence: true
end
