class CreateOrganizationAdmins < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_admins do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
