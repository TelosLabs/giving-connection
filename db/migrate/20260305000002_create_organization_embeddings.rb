# frozen_string_literal: true

class CreateOrganizationEmbeddings < ActiveRecord::Migration[7.2]
  def change
    create_table :organization_embeddings do |t|
      t.references :organization, null: false, foreign_key: true, index: {unique: true}
      t.column :embedding, :vector, limit: 1024, null: false
      t.text :text_snapshot, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
