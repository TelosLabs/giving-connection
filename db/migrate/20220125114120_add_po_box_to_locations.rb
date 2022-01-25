class AddPoBoxToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :po_box, :boolean
  end
end
