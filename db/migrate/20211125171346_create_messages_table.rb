class CreateMessagesTable < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :subject
      t.string :organization_name, null: false
      t.string :organization_website
      t.string :organization_ein
      t.text :content
    end
  end
end
