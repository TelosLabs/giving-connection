class AddProfileAdminNameAndEmailToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :profile_admin_name, :string
    add_column :messages, :profile_admin_email, :string
  end
end
