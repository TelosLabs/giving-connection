class CreateFavoriteBlogs < ActiveRecord::Migration[7.2]
  def change
    create_table :favorite_blogs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true

    end
  end
end
