class AddVolunteerAvailabilityToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :volunteer_availability, :boolean, null: false, default: false
  end
end
