class AddSpatialData < ActiveRecord::Migration[6.1]
  def change
    create_table :locations do |t|
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.st_point :lonlat, geographic: true, null: false
      t.timestamps

      t.index :lonlat, using: :gist
    end
  end
end
