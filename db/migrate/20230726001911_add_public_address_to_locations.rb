class AddPublicAddressToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :public_address, :boolean, default: true
  end
end
