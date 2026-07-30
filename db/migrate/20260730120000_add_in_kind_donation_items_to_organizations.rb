class AddInKindDonationItemsToOrganizations < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:organizations, :in_kind_donation_items)

    add_column :organizations, :in_kind_donation_items, :text
  end
end
