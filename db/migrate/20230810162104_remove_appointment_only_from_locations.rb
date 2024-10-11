class RemoveAppointmentOnlyFromLocations < ActiveRecord::Migration[6.1]
  def change
    remove_column :locations, :appointment_only, :boolean
  end
end
