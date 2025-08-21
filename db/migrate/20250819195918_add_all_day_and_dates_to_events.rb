class AddAllDayAndDatesToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :all_day, :boolean
    add_column :events, :start_date, :date
    add_column :events, :end_date, :date
  end
end
