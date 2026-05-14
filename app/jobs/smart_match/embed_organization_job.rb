# frozen_string_literal: true

module SmartMatch
  class EmbedOrganizationJob < ApplicationJob
    queue_as :default

    # Force EmbeddingClient (and its sibling error constants) to load so the
    # retry_on/discard_on references below resolve under Zeitwerk.
    SmartMatch::EmbeddingClient

    discard_on SmartMatch::PermanentError
    retry_on SmartMatch::EmbeddingUnavailableError, wait: :polynomially_longer, attempts: 5

    # Debounce window: after the first model callback enqueues a job for an
    # organization, subsequent callbacks (additional causes, beneficiaries,
    # location edits in the same save) within this window are coalesced into
    # the already-scheduled job. The job clears the key when it begins so a
    # later change re-enqueues normally.
    COALESCE_WINDOW = 30.seconds
    COALESCE_KEY_PREFIX = "smart_match:embed_org:scheduled"

    # Public entry point preferred over `perform_later` from model callbacks.
    # A nested-attributes save can fire after_commit on Organization,
    # OrganizationCause, OrganizationBeneficiary, and Location for the same
    # parent organization -- without coalescing that produces O(N) duplicate
    # jobs that all hit the single-worker Python service.
    def self.coalesce_for(organization_id)
      key = "#{COALESCE_KEY_PREFIX}:#{organization_id}"
      already_scheduled = !Rails.cache.write(key, true, unless_exist: true, expires_in: COALESCE_WINDOW)
      return if already_scheduled

      perform_later(organization_id)
    end

    def perform(organization_id)
      Rails.cache.delete("#{COALESCE_KEY_PREFIX}:#{organization_id}")

      organization = Organization.find_by(id: organization_id)
      unless organization
        Rails.logger.warn("[SmartMatch] Organization #{organization_id} not found, skipping embedding")
        return
      end

      text = OrganizationTextBuilder.call(organization: organization)
      unless text
        Rails.logger.warn("[SmartMatch] Organization #{organization_id} has no embeddable text, skipping")
        return
      end

      vector = EmbeddingClient.call(text: text)

      OrganizationEmbedding.upsert_for!(organization: organization, embedding: vector, text_snapshot: text)
    end
  end
end
