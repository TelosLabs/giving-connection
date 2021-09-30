class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :ein_number, null: false
      t.string :irs_ntee_code, null: false
      t.string :website
      t.string :scope_of_work, null: false
      t.references :creator, polymorphic: true

      t.timestamps

      t.index :name, unique: true
      t.index :ein_number, unique: true
      t.index :scope_of_work
    end
  end
end
