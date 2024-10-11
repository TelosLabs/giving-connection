class AddSecondNameToOrganization < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :second_name, :string
  end
end
