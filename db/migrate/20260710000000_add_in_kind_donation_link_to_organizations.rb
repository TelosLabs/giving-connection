class AddInKindDonationLinkToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :in_kind_donation_link, :string
  end
end
