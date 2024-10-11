class RemoveNullFromMessages < ActiveRecord::Migration[6.1]
  def change
    change_column_null :messages, :organization_name, true
  end
end
