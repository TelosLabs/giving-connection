class AddSuiteToLocation < ActiveRecord::Migration[6.1]
  def change
    add_column :locations, :suite, :string
  end
end
