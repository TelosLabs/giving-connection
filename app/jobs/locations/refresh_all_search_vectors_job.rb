# frozen_string_literal: true

module Locations
  # Full recompute of every location's search_vector. Used for the initial
  # backfill (lib/tasks/search.rake) and as a nightly self-healing pass
  # (config/clock.rb) for anything that slipped past the per-model callbacks
  # -- most notably bulk spreadsheet imports, which use activerecord-import
  # and so skip ActiveRecord callbacks entirely (see
  # SpreadsheetImport::SpreadsheetParser#attach_media for the same caveat
  # already documented for logo/cover attachment).
  #
  # Idempotent and safe to run repeatedly: recomputing an already-correct
  # search_vector is a no-op in effect, just some spent CPU. At current data
  # volume (order of 10^4 locations) a full pass is cheap enough that there's
  # no need for staleness tracking -- just recompute everything.
  class RefreshAllSearchVectorsJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 500

    def perform
      Location.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        Location.refresh_search_vector!(batch.map(&:id))
      end
    end
  end
end
