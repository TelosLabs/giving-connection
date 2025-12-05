class CreateNewsletter < ActiveRecord::Migration[7.2]
  def change
    create_table :newsletters do |t|
      t.string :email, null: false
      t.boolean :verified, default: false, null: false
      t.boolean :added, default: false, null: false
      t.string :verification_token

      t.timestamps
    end
    
    add_index :newsletters, :email, unique: true
    add_index :newsletters, :verification_token, unique: true
  end
end
