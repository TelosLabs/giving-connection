class CreateLocationCauses < ActiveRecord::Migration[6.1]
  def change
    create_table :location_causes do |t|
      t.references :location, null: false, foreign_key: true
      t.references :cause, null: false, foreign_key: true

      t.timestamps
    end
  end
end
