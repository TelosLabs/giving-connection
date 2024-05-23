class RemoveUniquenessFromEinNumber < ActiveRecord::Migration[6.1]
  def change
    remove_index :organizations, :ein_number
    add_index :organizations, :ein_number
  end
end
