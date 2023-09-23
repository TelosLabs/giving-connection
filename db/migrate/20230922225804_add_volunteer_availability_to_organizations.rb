class AddVolunteerAvailabilityToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :volunteer_availability, :boolean, default: false
  end
end
