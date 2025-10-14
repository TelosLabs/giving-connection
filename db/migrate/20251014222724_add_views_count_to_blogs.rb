class AddViewsCountToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :views_count, :integer, null: false, default: 0
  end
end
