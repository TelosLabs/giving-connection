class CreateImportLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :import_logs do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :file_name
      t.integer :total_rows
      t.integer :success_count
      t.integer :error_count
      t.integer :skipped_count
      t.string :status
      t.text :error_messages

      t.timestamps
    end
  end
end
