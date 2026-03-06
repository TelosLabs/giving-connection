# frozen_string_literal: true

class AddVectorIndexToOrganizationEmbeddings < ActiveRecord::Migration[7.2]
  def change
    add_index :organization_embeddings, :embedding,
      using: :hnsw,
      opclass: :vector_cosine_ops,
      name: "idx_org_embeddings_hnsw_cosine"
  end
end
