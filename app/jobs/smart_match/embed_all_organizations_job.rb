# frozen_string_literal: true

module SmartMatch
  class EmbedAllOrganizationsJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 50

    def perform
      Organization.active.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        texts = batch.map { |org| OrganizationTextBuilder.call(organization: org) }
        org_text_pairs = batch.zip(texts).reject { |_, text| text.nil? }

        next if org_text_pairs.empty?

        vectors = EmbeddingClient.embed_batch(texts: org_text_pairs.map(&:last))

        org_text_pairs.each_with_index do |(org, text), index|
          OrganizationEmbedding.upsert_for!(organization: org, embedding: vectors[index], text_snapshot: text)
        end
      end
    end
  end
end
