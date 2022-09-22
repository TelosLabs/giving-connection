class AddImagesToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :images, :json
  end
end
