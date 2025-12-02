class CreateBlogLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :blog_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true

      t.timestamps
    end

    add_index :blog_likes, [:user_id, :blog_id], unique: true, name: "idx_blog_likes_user_blog"
  end
end
