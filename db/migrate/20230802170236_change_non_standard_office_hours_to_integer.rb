class ChangeNonStandardOfficeHoursToInteger < ActiveRecord::Migration[6.1]
  def change
    change_column_null :locations, :non_standard_office_hours, true
    change_column :locations, :non_standard_office_hours, :integer, using: "case when non_standard_office_hours then 1 else null end", default: nil
  end
end
