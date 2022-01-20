class AddEmailToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :email, :string
  end
end
