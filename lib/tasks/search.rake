# frozen_string_literal: true

namespace :search do
  desc "Backfill/recompute locations.search_vector for every location"
  task backfill_search_vectors: :environment do
    total = Location.count
    Locations::RefreshAllSearchVectorsJob.perform_now
    puts({
      total_locations: total,
      populated: Location.where.not(search_vector: nil).count
    }.to_json)
  end
end
