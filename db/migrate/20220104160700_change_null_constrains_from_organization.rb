class ChangeNullConstrainsFromOrganization < ActiveRecord::Migration[6.1]
  def change
    change_column_null :organizations, :vision_statement_en, true
    change_column_null :organizations, :tagline_en, true
  end
end
