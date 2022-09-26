class RemoveImagesFromLocation < ActiveRecord::Migration[6.1]
  def change
    remove_column :locations, :images, :json
  end
end
