class AddProfileAdminNameAndEmailToMessages < ActiveRecord::Migration[6.1]
  def change
    reversible do |direction|
      direction.up do
        # avoids default '' and adds the null contraint at the same time
        add_column :messages, :profile_admin_name, :string
        add_column :messages, :profile_admin_email, :string
        Message.all.each do |message|
          message.update!(profile_admin_name: message.name)
          message.update!(profile_admin_email: message.email)
        end
        change_column_null :messages, :profile_admin_name, false
        change_column_null :messages, :profile_admin_email, false
      end
      direction.down do
        remove_column :messages, :profile_admin_name
        remove_column :messages, :profile_admin_email
      end
    end

    add_index :messages, :name
    add_index :messages, :organization_name
  end
end
