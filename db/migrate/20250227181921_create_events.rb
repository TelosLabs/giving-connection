class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :link
      t.string :image_link
      t.string :location
      t.boolean :published, default: false
      t.boolean :isRecurring, default: false

      # Arrays for categorization
      t.string :type_of_event, array: true, default: []
      t.string :tags, array: true, default: []
      t.string :categories, array: true, default: []
      t.string :subcategories, array: true, default: []

      # Foreign key to tie events to organizations
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
