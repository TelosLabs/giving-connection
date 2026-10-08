# frozen_string_literal: true

module Locations
  class RefreshSearchVectorJob < ApplicationJob
    queue_as :default

    # Debounce window: mirrors SmartMatch::EmbedOrganizationJob. A nested-
    # attributes save can fire after_commit on Organization, OrganizationCause,
    # Tag, and SocialMedia for the same parent organization -- without
    # coalescing that produces O(N) duplicate reindex jobs for one edit.
    COALESCE_WINDOW = 30.seconds
    COALESCE_KEY_PREFIX = "locations:refresh_search_vector:scheduled"

    # Public entry point preferred over `perform_later` from model callbacks.
    def self.coalesce_for_organization(organization_id)
      key = "#{COALESCE_KEY_PREFIX}:#{organization_id}"
      already_scheduled = !Rails.cache.write(key, true, unless_exist: true, expires_in: COALESCE_WINDOW)
      return if already_scheduled

      perform_later(organization_id)
    end

    def perform(organization_id)
      Rails.cache.delete("#{COALESCE_KEY_PREFIX}:#{organization_id}")

      location_ids = Location.where(organization_id: organization_id).ids
      Location.refresh_search_vector!(location_ids)
    end
  end
end
