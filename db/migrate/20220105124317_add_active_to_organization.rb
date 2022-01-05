class AddActiveToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :active, :boolean, default: true
  end
end
