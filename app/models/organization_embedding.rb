# frozen_string_literal: true

class OrganizationEmbedding < ApplicationRecord
  belongs_to :organization
  has_neighbors :embedding

  validates :embedding, presence: true
  validates :text_snapshot, presence: true

  # Atomic upsert keyed on organization_id. Uses INSERT ... ON CONFLICT so
  # concurrent EmbedOrganizationJob runs cannot race -- the database picks
  # one winner per concurrent transaction and the other(s) receive their
  # write applied via DO UPDATE rather than racing against a separate UPDATE.
  #
  # Returns the upserted record reloaded from the database.
  def self.upsert_for!(organization:, embedding:, text_snapshot:)
    now = Time.current
    result = upsert(
      {
        organization_id: organization.id,
        embedding: embedding,
        text_snapshot: text_snapshot,
        created_at: now,
        updated_at: now
      },
      unique_by: :index_organization_embeddings_on_organization_id,
      returning: %w[id]
    )
    find(result.rows.first.first)
  end
end
