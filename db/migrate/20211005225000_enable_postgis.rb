class EnablePostgis < ActiveRecord::Migration[7.2]
  def up
    enable_extension "postgis"
  end

  def down
    disable_extension "postgis"
  end
end
