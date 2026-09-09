# frozen_string_literal: true

class AddStateCodeToLocations < ActiveRecord::Migration[7.1]
  # SimilarityQuery filters orgs by US state. Without a structured column we
  # match `address ILIKE '%TN%'`, which (a) matches "Patten, ME" and similar
  # false positives, and (b) cannot use any index -- full table scan on
  # every quiz completion.
  #
  # A 2-char state_code column with a btree index lets the filter become
  # `locations.state_code = ?`. Backfill is a separate step (rake task
  # `smart_match:backfill_location_state_codes`); SimilarityQuery falls back
  # to ILIKE for rows where state_code is still NULL.
  def change
    add_column :locations, :state_code, :string, limit: 2
    add_index :locations, :state_code
  end
end
