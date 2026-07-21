class OrganizationCause < ApplicationRecord
  belongs_to :cause
  belongs_to :organization

  after_commit :schedule_org_embedding_update, on: [:create, :destroy]

  private

  def schedule_org_embedding_update
    SmartMatch::EmbedOrganizationJob.coalesce_for(organization_id)
  rescue => e
    # Embedding refresh is best-effort. A queue/cache (Redis) outage must not
    # roll back or block an otherwise-valid save.
    Rails.logger.error("[SmartMatch] Failed to schedule embedding update for organization #{organization_id}: #{e.class}: #{e.message}")
  end
end
