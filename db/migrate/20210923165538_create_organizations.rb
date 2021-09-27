class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :ein_number, unique: true
      t.string :irs_ntee_code
      t.string :website
      t.string :scope_of_work
      t.references :creator, polymorphic: true

      t.timestamps
    end
  end
end
