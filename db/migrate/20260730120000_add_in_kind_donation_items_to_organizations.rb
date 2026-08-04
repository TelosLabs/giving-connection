class AddInKindDonationItemsToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :in_kind_donation_items, :jsonb, null: false, default: []
  end
end
