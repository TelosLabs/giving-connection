class CreateTags < ActiveRecord::Migration[6.1]
  def change
    create_table :tags do |t|
      t.string :name
      t.references :organization, null: false, foreign_key: true
      t.index :name
      
      t.timestamps
    end
  end
end
