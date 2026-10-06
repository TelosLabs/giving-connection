# frozen_string_literal: true

# == Schema Information
#
# Table name: social_medias
#
#  id              :bigint           not null, primary key
#  facebook        :string
#  instagram       :string
#  twitter         :string
#  linkedin        :string
#  youtube         :string
#  blog            :string
#  organization_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class SocialMedia < ApplicationRecord
  belongs_to :organization

  after_commit :schedule_search_vector_update, on: [:create, :update, :destroy]

  private

  def schedule_search_vector_update
    Locations::RefreshSearchVectorJob.coalesce_for_organization(organization_id)
  rescue => e
    # Search indexing is best-effort. A queue/cache (Redis) outage must not
    # roll back or block an otherwise-valid save.
    Rails.logger.error("[Search] Failed to schedule search_vector update for organization #{organization_id}: #{e.class}: #{e.message}")
  end
end
