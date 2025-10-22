class AddTopicToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :topic, :string
  end
end
