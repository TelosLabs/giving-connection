class AddAlwaysOpenToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :always_open, :boolean, null: false, default: true
  end
end
