class RecommendationFeedback < ApplicationRecord
  belongs_to :user, optional: true

  validates :nonprofit_id, presence: true
  validates :feedback_type, presence: true, inclusion: {in: %w[like dislike]}
  validates :session_id, presence: true
  validates :session_id, uniqueness: {scope: :nonprofit_id, message: "You've already provided feedback for this nonprofit"}

  scope :likes, -> { where(feedback_type: "like") }
  scope :dislikes, -> { where(feedback_type: "dislike") }

  def self.feedback_given?(session_id, nonprofit_id)
    exists?(session_id: session_id, nonprofit_id: nonprofit_id)
  end

  def self.get_feedback(session_id, nonprofit_id)
    find_by(session_id: session_id, nonprofit_id: nonprofit_id)
  end
end
