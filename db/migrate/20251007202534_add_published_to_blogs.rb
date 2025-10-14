class AddPublishedToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :published, :boolean, null: false, default: false
    add_index :blogs, :published
    # rubocop:disable Rails/ReversibleMigration
    execute "UPDATE blogs SET published = FALSE WHERE published IS NULL"
    # rubocop:enable Rails/ReversibleMigration
  end
end
