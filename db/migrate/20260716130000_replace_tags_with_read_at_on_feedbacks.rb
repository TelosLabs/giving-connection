# frozen_string_literal: true

class ReplaceTagsWithReadAtOnFeedbacks < ActiveRecord::Migration[7.2]
  def change
    remove_column :feedbacks, :tags, :string
    add_column :feedbacks, :read_at, :datetime
    add_index :feedbacks, :read_at
  end
end
