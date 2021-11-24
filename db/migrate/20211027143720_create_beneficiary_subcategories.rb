# frozen_string_literal: true

class CreateBeneficiarySubcategories < ActiveRecord::Migration[6.1]
  def change
    create_table :beneficiary_subcategories do |t|
      t.string :name
      t.references :beneficiary_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
