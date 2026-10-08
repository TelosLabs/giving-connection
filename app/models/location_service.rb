# frozen_string_literal: true

# == Schema Information
#
# Table name: location_services
#
#  id          :bigint           not null, primary key
#  description :string
#  location_id :bigint           not null
#  service_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class LocationService < ApplicationRecord
  belongs_to :location
  belongs_to :service

  after_commit :schedule_search_vector_update, on: [:create, :destroy]

  private

  # Refreshes the whole organization's locations rather than just this one,
  # same simplification SmartMatch::EmbedOrganizationJob already makes for
  # location-level changes -- one coalescing key (organization_id) instead of
  # per-location, which matters more once an org has several locations.
  def schedule_search_vector_update
    Locations::RefreshSearchVectorJob.coalesce_for_organization(location.organization_id)
  rescue => e
    # Search indexing is best-effort. A queue/cache (Redis) outage must not
    # roll back or block an otherwise-valid save.
    Rails.logger.error("[Search] Failed to schedule search_vector update for location_service #{id}: #{e.class}: #{e.message}")
    Rollbar.error(e, "Failed to schedule search_vector update for location_service #{id}")
  end
end
