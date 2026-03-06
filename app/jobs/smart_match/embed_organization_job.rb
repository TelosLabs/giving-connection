# frozen_string_literal: true

module SmartMatch
  class EmbedOrganizationJob < ApplicationJob
    queue_as :default

    def perform(organization_id)
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

      OrganizationEmbedding.find_or_initialize_by(organization: organization).tap do |embedding|
        embedding.update!(embedding: vector, text_snapshot: text)
      end
    end
  end
end
