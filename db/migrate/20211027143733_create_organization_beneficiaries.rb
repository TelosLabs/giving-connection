class CreateOrganizationBeneficiaries < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_beneficiaries do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :beneficiary_subcategory, null: false, foreign_key: true

      t.timestamps
    end
  end
end
