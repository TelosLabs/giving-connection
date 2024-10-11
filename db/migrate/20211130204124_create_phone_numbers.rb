class CreatePhoneNumbers < ActiveRecord::Migration[6.1]
  def change
    create_table :phone_numbers do |t|
      t.string :number
      t.boolean :main
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
