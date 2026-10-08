# frozen_string_literal: true

# Precomputed, indexed replacement for the tsvector `Location.search_by_keyword`
# used to build from scratch on every request (no GIN index backed it, so
# every search was a full sequential scan recomputing text search weights
# across 5+ joined tables). Nullable with no default so this add is a fast
# metadata-only change; Locations::Searchable.refresh! backfills it.
class AddSearchVectorToLocations < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :locations, :search_vector, :tsvector
    add_index :locations, :search_vector, using: :gin, algorithm: :concurrently, if_not_exists: true
  end
end
