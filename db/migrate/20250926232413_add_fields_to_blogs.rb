class AddFieldsToBlogs < ActiveRecord::Migration[7.2]
  def change
    add_column :blogs, :name, :string
    add_column :blogs, :email, :string
    add_column :blogs, :impact_tag, :string
  end
end
