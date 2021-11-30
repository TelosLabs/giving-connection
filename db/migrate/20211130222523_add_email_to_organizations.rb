class AddEmailToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :emai, :string
  end
end
