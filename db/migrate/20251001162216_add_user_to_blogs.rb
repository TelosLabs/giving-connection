class AddUserToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_reference :blogs, :user, null: true, foreign_key: true
  end
end
