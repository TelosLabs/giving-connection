class CreateOrganizations < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :ein_number, unique: true
      t.string :irs_ntee_code
      t.text :mission_statement
      t.text :vision_statement
      t.text :tagline
      t.text :description
      t.text :impact
      t.string :website
      t.string :scope_of_working
      t.references :created_by, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
