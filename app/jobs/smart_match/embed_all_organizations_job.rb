# frozen_string_literal: true

module SmartMatch
  class EmbedAllOrganizationsJob < ApplicationJob
    queue_as :default

    # Force EmbeddingClient (and its sibling error constants) to load so the
    # retry_on/discard_on references below resolve under Zeitwerk.
    SmartMatch::EmbeddingClient

    discard_on SmartMatch::PermanentError
    retry_on SmartMatch::EmbeddingUnavailableError, wait: :polynomially_longer, attempts: 5

    BATCH_SIZE = 50

    def perform
      scope = Organization.active.includes(:causes, :beneficiary_subcategories, :main_location)

      scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        org_text_pairs = batch.filter_map do |org|
          text = OrganizationTextBuilder.call(organization: org)
          [org, text] if text
        end

        next if org_text_pairs.empty?

        texts = org_text_pairs.map(&:last)
        vectors = EmbeddingClient.embed_batch(texts: texts)

        if vectors.length != texts.length
          raise SmartMatch::EmbeddingUnavailableError,
            "Embedding batch mismatch: expected #{texts.length} vectors, got #{vectors.length}"
        end

        org_text_pairs.each_with_index do |(org, text), index|
          OrganizationEmbedding.upsert_for!(organization: org, embedding: vectors[index], text_snapshot: text)
        rescue => e
          # One bad org should not abort the entire batch; fall back to per-org
          # job which has its own retry/discard semantics.
          Rails.logger.error("[SmartMatch] Failed to upsert embedding for organization #{org.id}: #{e.class}: #{e.message}")
          SmartMatch::EmbedOrganizationJob.perform_later(org.id)
        end
      end
    end
  end
end
