class RemoveDescriptionFromOrgs < ActiveRecord::Migration[6.1]
  def change
    remove_column :organizations, :description_en
    remove_column :organizations, :description_es
  end
end
