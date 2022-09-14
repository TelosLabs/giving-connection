class AddProfileAdminNameAndEmailToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :profile_admin_name, :string
    add_column :messages, :profile_admin_email, :string
    add_index :messages, :name
    add_index :messages, :organization_name
    change_column_null :messages, :subject, false
    change_column_null :messages, :organization_name, false
    change_column_null :messages, :content, false
  end
end
