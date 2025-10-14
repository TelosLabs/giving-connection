class AddUniqueIndexesToBlogLikesAndFavoriteBlogs < ActiveRecord::Migration[7.2]
  def change
    add_index :blog_likes, [:user_id, :blog_id], unique: true, name: "idx_blog_likes_user_blog"
    add_index :favorite_blogs, [:user_id, :blog_id], unique: true, name: "idx_favorite_blogs_user_blog"
  end
end
