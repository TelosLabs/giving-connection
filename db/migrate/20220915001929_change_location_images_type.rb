class ChangeLocationImagesType < ActiveRecord::Migration[6.1]
  def change
    remove_column :locations, :images
    add_column :locations, :images, :jsonb, default: []
  end
end
