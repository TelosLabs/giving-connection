# frozen_string_literal: true

class ConstrainQuizSubmissionsEmbeddingDimension < ActiveRecord::Migration[7.1]
  # quiz_submissions was created with `t.column :embedding, :vector, limit: 1024`
  # but Postgres ignored the limit at create-table time (pgvector dimension
  # constraint must be set via ALTER TABLE ... TYPE vector(N)), so the column
  # accepts any-dimension vectors. organization_embeddings was constrained
  # explicitly in migration 20260305000005; this aligns quiz_submissions with it.
  def up
    return unless column_exists?(:quiz_submissions, :embedding)

    execute "ALTER TABLE quiz_submissions ALTER COLUMN embedding TYPE vector(1024)"
  end

  def down
    return unless column_exists?(:quiz_submissions, :embedding)

    execute "ALTER TABLE quiz_submissions ALTER COLUMN embedding TYPE vector"
  end
end
