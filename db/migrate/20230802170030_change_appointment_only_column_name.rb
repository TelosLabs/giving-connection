class ChangeAppointmentOnlyColumnName < ActiveRecord::Migration[6.1]
  def change
    rename_column :locations, :appointment_only, :non_standard_office_hours
  end
end
