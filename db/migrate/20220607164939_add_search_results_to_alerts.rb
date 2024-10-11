class AddSearchResultsToAlerts < ActiveRecord::Migration[6.1]
  def change
    add_column :alerts, :search_results, :string, array: true, default: []
  end
end
