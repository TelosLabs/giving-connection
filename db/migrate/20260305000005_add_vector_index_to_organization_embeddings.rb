# frozen_string_literal: true

class AddVectorIndexToOrganizationEmbeddings < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE organization_embeddings ALTER COLUMN embedding TYPE vector(1024)"
    add_index :organization_embeddings, :embedding,
      using: :hnsw,
      opclass: :vector_cosine_ops,
      name: "idx_org_embeddings_hnsw_cosine"
  end

  def down
    remove_index :organization_embeddings, name: "idx_org_embeddings_hnsw_cosine"
    execute "ALTER TABLE organization_embeddings ALTER COLUMN embedding TYPE vector(1024)"
  end
end
