# frozen_string_literal: true

class CreateContactInformations < ActiveRecord::Migration[6.1]
  def change
    create_table :contact_informations do |t|
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :email
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
