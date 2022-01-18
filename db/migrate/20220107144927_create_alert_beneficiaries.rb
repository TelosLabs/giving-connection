class CreateAlertBeneficiaries < ActiveRecord::Migration[6.1]
  def change
    create_table :alert_beneficiaries do |t|
      t.references :alert, null: false, foreign_key: true
      t.references :beneficiary_subcategory, null: false, foreign_key: true

      t.timestamps
    end
  end
end
