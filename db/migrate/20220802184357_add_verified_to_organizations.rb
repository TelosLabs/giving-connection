class AddVerifiedToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :verified, :boolean, default: false
  end
end
