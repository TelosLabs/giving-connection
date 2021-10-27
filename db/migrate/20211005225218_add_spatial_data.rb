# frozen_string_literal: true

class AddSpatialData < ActiveRecord::Migration[6.1]
  def change
    create_table :locations do |t|
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.st_point :lonlat, geographic: true, null: false
      t.string :website
      t.boolean :main, null: false, default: false
      t.boolean :physical
      t.boolean :offer_services
      t.references :organization, foreign_key: true
      t.timestamps

      t.index :lonlat, using: :gist
    end
  end
end
