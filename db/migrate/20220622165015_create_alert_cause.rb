class CreateAlertCause < ActiveRecord::Migration[6.1]
  def change
    create_table :alert_causes do |t|
      t.references :alert, null: false, foreign_key: true
      t.references :cause, null: false, foreign_key: true

      t.timestamps
    end
  end
end
