class AddTimestampsToBlogLikesAndFavoriteBlogs < ActiveRecord::Migration[7.2]
  def up
    add_timestamps :blog_likes, null: true
    add_timestamps :favorite_blogs, null: true

    now = Time.current
    BlogLike.update_all(created_at: now, updated_at: now)
    FavoriteBlog.update_all(created_at: now, updated_at: now)

    change_column_null :blog_likes, :created_at, false
    change_column_null :blog_likes, :updated_at, false
    change_column_null :favorite_blogs, :created_at, false
    change_column_null :favorite_blogs, :updated_at, false
  end

  def down
    remove_column :blog_likes, :created_at
    remove_column :blog_likes, :updated_at
    remove_column :favorite_blogs, :created_at
    remove_column :favorite_blogs, :updated_at
  end
end
