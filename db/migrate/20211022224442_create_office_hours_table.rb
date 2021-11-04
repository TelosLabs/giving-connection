class CreateOfficeHoursTable < ActiveRecord::Migration[6.1]
  def change
    create_table :office_hours do |t|
      t.string :day, null: false
      t.time :open_time
      t.time :close_time
      t.boolean :closed, default: false
      t.timestamps
      t.references :location
    end
  end
end
