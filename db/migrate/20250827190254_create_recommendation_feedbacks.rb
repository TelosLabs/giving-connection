class CreateRecommendationFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :recommendation_feedbacks do |t|
      t.references :user, null: true, foreign_key: true
      t.string :nonprofit_id, null: false
      t.string :feedback_type, null: false
      t.string :session_id, null: false
      t.text :user_answers
      t.text :recommendation_data

      t.timestamps
    end

    add_index :recommendation_feedbacks, [:session_id, :nonprofit_id], unique: true
    add_index :recommendation_feedbacks, :feedback_type
  end
end
