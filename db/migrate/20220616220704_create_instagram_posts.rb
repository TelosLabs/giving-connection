class CreateInstagramPosts < ActiveRecord::Migration[6.1]
  def change
    create_table :instagram_posts do |t|
      t.string :media_url, null: false
      t.string :post_url, null: false
      t.bigint :external_id, null: false
      t.string :media_type, null: false
      t.datetime :creation_date, null: false
      t.timestamps
    end
  end
end
