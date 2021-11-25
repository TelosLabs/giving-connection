class AddNameToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :name, :string, null: false
  end
end
