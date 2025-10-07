class RemoveContentFromBlogs < ActiveRecord::Migration[7.2]
  def change
    remove_column :blogs, :content, :text
  end
end
