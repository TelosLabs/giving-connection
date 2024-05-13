class AddTimeZoneToLocation < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :time_zone, :string
  end
end
