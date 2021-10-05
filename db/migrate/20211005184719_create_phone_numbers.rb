class CreatePhoneNumbers < ActiveRecord::Migration[6.1]
  def change
    create_table :phone_numbers do |t|
      t.string :number
      t.boolean :main, default: true
      t.references :contact_information, null: false, foreign_key: true

      t.timestamps
    end
  end
end
