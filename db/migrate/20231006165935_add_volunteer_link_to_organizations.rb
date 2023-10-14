class AddVolunteerLinkToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :volunteer_link, :string
  end
end
