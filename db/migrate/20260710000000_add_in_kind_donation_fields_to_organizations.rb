class AddInKindDonationFieldsToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :in_kind_donation_link, :string
    add_column :organizations, :in_kind_donation_items, :text
  end
end
