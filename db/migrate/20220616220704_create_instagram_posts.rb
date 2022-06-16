class CreateInstagramPosts < ActiveRecord::Migration[6.1]
  def change
    create_table :instagram_posts do |t|
      t.string :media_url
      t.string :post_url
      t.bigint :external_id
      t.datetime :creation_date
      t.timestamps
    end
  end
end
