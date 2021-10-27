class CreateBeneficiarySubcategories < ActiveRecord::Migration[6.1]
  def change
    create_table :beneficiary_subcategories do |t|
      t.string :name
      t.references :beneficiary, null: false, foreign_key: true

      t.timestamps
    end
  end
end
