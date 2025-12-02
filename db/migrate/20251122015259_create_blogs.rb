class CreateBlogs < ActiveRecord::Migration[7.2]
  def change
    create_table :blogs do |t|
      t.string :title, null: false
      t.string :name
      t.string :email
      t.text :impact_tag, array: true, default: []
      t.string :blog_tag
      t.string :topic
      t.boolean :published, null: false, default: false
      t.integer :views_count, null: false, default: 0
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :blogs, :published
  end
end
