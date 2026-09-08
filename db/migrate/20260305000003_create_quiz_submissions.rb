# frozen_string_literal: true

class CreateQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_submissions do |t|
      t.references :user, null: true, foreign_key: true, index: true
      t.string :session_id, null: false, index: true
      t.jsonb :answers, default: {}
      t.string :user_type, null: false
      t.column :embedding, :vector, limit: 1024, null: false
      t.text :text_snapshot, null: false

      t.timestamps
    end
  end
end
