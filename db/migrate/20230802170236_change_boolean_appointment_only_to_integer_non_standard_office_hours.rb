class ChangeBooleanAppointmentOnlyToIntegerNonStandardOfficeHours < ActiveRecord::Migration[6.1]
  def change
    change_column_null :locations, :appointment_only, true
    change_column :locations, :appointment_only, :integer, using: "case when appointment_only then 1 else null end", default: nil
    rename_column :locations, :appointment_only, :non_standard_office_hours
  end
end
