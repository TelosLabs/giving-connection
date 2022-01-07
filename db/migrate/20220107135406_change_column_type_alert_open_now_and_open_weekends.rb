class ChangeColumnTypeAlertOpenNowAndOpenWeekends < ActiveRecord::Migration[6.1]
  def change
    change_column :alerts, :open_now, 'boolean USING CAST(open_now AS boolean)'
    change_column :alerts, :open_weekends, 'boolean USING CAST(open_weekends AS boolean)'
  end
end
