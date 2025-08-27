class AddUniqueIndexToRecommendationFeedbacks < ActiveRecord::Migration[7.2]
  def change
    add_index :recommendation_feedbacks, [:session_id, :nonprofit_id], unique: true
    add_index :recommendation_feedbacks, :feedback_type
  end
end
