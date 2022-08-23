class RemoveNullFalseFromOrgCause < ActiveRecord::Migration[6.1]
  def change
    change_column_null :organization_causes, :organization_id, true
  end
end
