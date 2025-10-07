class AddPublishedToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :published, :boolean, null: false, default: false
    add_index  :blogs, :published
    execute "UPDATE blogs SET published = FALSE WHERE published IS NULL"
  end
end
