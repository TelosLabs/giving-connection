class AddDefaultFalseToPoBoxForLocations < ActiveRecord::Migration[6.1]
  def change
    change_column_default :locations, :po_box, from: nil, to: false
  end
end
