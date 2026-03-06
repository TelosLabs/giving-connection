# frozen_string_literal: true

class OrganizationEmbedding < ApplicationRecord
  belongs_to :organization
  has_neighbors :embedding

  validates :embedding, presence: true
  validates :text_snapshot, presence: true

  def stale?
    text_snapshot != SmartMatch::OrganizationTextBuilder.call(organization: organization)
  end
end
