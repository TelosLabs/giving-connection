# rubocop:disable Rails/CreateTableWithTimestamps
class CreateBlogLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :blog_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
