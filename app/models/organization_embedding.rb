# frozen_string_literal: true

class OrganizationEmbedding < ApplicationRecord
  belongs_to :organization
  has_neighbors :embedding

  validates :embedding, presence: true
  validates :text_snapshot, presence: true

  def self.upsert_for!(organization:, embedding:, text_snapshot:)
    find_or_initialize_by(organization: organization).tap do |record|
      record.update!(embedding: embedding, text_snapshot: text_snapshot)
    end
  end

  def stale?
    text_snapshot != SmartMatch::OrganizationTextBuilder.call(organization: organization)
  end
end
