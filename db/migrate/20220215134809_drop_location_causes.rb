class DropLocationCauses < ActiveRecord::Migration[6.1]
  def change
    drop_table :location_causes
  end
end
