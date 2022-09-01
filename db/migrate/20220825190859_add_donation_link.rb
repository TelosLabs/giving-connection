class AddDonationLink < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :donation_link, :string
  end
end
