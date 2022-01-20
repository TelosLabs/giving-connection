# frozen_string_literal: true

class CreateBeneficiaryGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :beneficiary_groups do |t|
      t.string :name

      t.timestamps
    end
  end
end
