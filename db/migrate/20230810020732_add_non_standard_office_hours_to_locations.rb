class AddNonStandardOfficeHoursToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :non_standard_office_hours, :integer
  end
end
