class AddGeneralPopulationServingToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :general_population_serving, :boolean, null: false, default: false
  end
end
