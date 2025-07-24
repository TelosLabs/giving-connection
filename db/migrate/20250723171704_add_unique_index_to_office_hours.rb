class AddUniqueIndexToOfficeHours < ActiveRecord::Migration[6.1]
  def change
    add_index :office_hours, [:location_id, :day], unique: true, name: "index_office_hours_on_location_id_and_day_unique"
  end
end
