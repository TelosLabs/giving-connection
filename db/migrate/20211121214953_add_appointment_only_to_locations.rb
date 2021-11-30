class AddAppointmentOnlyToLocations < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :appointment_only, :boolean, default: false
  end
end
