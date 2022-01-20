class AddPhoneNumberToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :phone_number, :string
  end
end
