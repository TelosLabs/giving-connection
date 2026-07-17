# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[7.2]
  def change
    create_table :feedbacks do |t|
      t.integer :rating, null: false
      t.string :category
      t.string :context
      t.text :comment
      t.string :page_url
      t.references :user, null: true, foreign_key: true
      t.datetime :read_at

      t.timestamps
    end

    add_index :feedbacks, :read_at
  end
end
