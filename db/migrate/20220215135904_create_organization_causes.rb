class CreateOrganizationCauses < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_causes do |t|
      t.references :cause, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
