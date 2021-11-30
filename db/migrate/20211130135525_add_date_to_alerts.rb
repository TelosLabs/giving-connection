class AddDateToAlerts < ActiveRecord::Migration[6.1]
  def change
    add_column :alerts, :next_alert, :date
  end
end
