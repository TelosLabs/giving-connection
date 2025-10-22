class AddBlogTagToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :blog_tag, :string
  end
end
