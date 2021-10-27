# frozen_string_literal: true

class CreateBeneficiaries < ActiveRecord::Migration[6.1]
  def change
    create_table :beneficiaries do |t|
      t.string :name

      t.timestamps
    end
  end
end
