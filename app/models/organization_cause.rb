class OrganizationCause < ApplicationRecord
  belongs_to :cause
  belongs_to :organization

  after_commit :schedule_org_embedding_update, on: [:create, :destroy]

  private

  def schedule_org_embedding_update
    SmartMatch::EmbedOrganizationJob.coalesce_for(organization_id)
  end
end
