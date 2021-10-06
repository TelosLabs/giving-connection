class AddSpatialData < ActiveRecord::Migration[6.1]
  def change
    create_table :branches do |t|
      t.string :address
      t.st_point :lonlat, geographic: true, null: false
    end
  end
end
