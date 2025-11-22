class CreateFavoriteBlogs < ActiveRecord::Migration[7.2]
  def change
    create_table :favorite_blogs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true

      t.timestamps
    end

    add_index :favorite_blogs, [:user_id, :blog_id], unique: true, name: "idx_favorite_blogs_user_blog"
  end
end