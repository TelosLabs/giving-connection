class CreateAlertServices < ActiveRecord::Migration[6.1]
  def change
    create_table :alert_services do |t|
      t.references :alert, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end
  end
end
