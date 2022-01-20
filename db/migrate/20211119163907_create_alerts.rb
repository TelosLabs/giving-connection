class CreateAlerts < ActiveRecord::Migration[6.1]
  def change
    create_table :alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :distance
      t.string :city
      t.string :state
      t.string :services
      t.string :open_now
      t.string :open_weekends
      t.string :keyword
      t.string :beneficiary_groups
      t.string :frequency, default: "weekly"

      t.timestamps
    end
  end
end
