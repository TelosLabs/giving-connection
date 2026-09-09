# frozen_string_literal: true

# Smart Match top-level namespace plus shared frozen configuration.
#
# This file is what Zeitwerk loads for `SmartMatch` as an explicit namespace.
# It MUST live under `app/services/` (alongside the smart_match/ subdirectory
# Zeitwerk uses to autoload SmartMatch::* children). Defining these constants
# from a config/initializers/*.rb file is unreliable: the initializer runs at
# boot before Zeitwerk takes over the namespace, and in development the
# constants disappear after the first code reload because Zeitwerk recreates
# the SmartMatch module.
#
# YAMLs load on every file evaluation -- once at boot, again on each dev
# reload. They are deep-frozen so accidental mutation in a request raises
# FrozenError instead of silently poisoning subsequent reads.

require "yaml"

module SmartMatch
  def self.deep_freeze(obj)
    case obj
    when Hash
      obj.each_value { |v| deep_freeze(v) }
      obj.freeze
    when Array
      obj.each { |v| deep_freeze(v) }
      obj.freeze
    when String
      obj.freeze
    else
      obj
    end
  end

  MATCHING_RULES = deep_freeze(YAML.safe_load_file(Rails.root.join("config/matching_rules.yml")))
  CITY_CENTROIDS = deep_freeze(YAML.safe_load_file(Rails.root.join("config/city_centroids.yml")))
  # Per-answer scoring table transcribed from the client's spec. See
  # docs/smart-match-scoring/ for the source CSVs and the semantics.
  SCORING_RULES = deep_freeze(YAML.safe_load_file(Rails.root.join("config/smart_match_scoring.yml")))

  # Shared upper bound for any text we hand to the BGE embedding service.
  # Referenced by UserIntent#to_embedding_text and Organization#smart_match_text
  # so both producers stay aligned with the same character budget.
  EMBEDDING_TEXT_MAX_LENGTH = 1500

  # US states (+ DC & PR) offered in the quiz's "Other location" picker. Keyed
  # by 2-letter code so the stored value matches Location#state_code exactly
  # (SimilarityQuery filters on that column). Names are the display labels.
  US_STATES = deep_freeze(
    {
      "AL" => "Alabama", "AK" => "Alaska", "AZ" => "Arizona", "AR" => "Arkansas",
      "CA" => "California", "CO" => "Colorado", "CT" => "Connecticut",
      "DE" => "Delaware", "DC" => "District of Columbia", "FL" => "Florida",
      "GA" => "Georgia", "HI" => "Hawaii", "ID" => "Idaho", "IL" => "Illinois",
      "IN" => "Indiana", "IA" => "Iowa", "KS" => "Kansas", "KY" => "Kentucky",
      "LA" => "Louisiana", "ME" => "Maine", "MD" => "Maryland",
      "MA" => "Massachusetts", "MI" => "Michigan", "MN" => "Minnesota",
      "MS" => "Mississippi", "MO" => "Missouri", "MT" => "Montana",
      "NE" => "Nebraska", "NV" => "Nevada", "NH" => "New Hampshire",
      "NJ" => "New Jersey", "NM" => "New Mexico", "NY" => "New York",
      "NC" => "North Carolina", "ND" => "North Dakota", "OH" => "Ohio",
      "OK" => "Oklahoma", "OR" => "Oregon", "PA" => "Pennsylvania",
      "PR" => "Puerto Rico", "RI" => "Rhode Island", "SC" => "South Carolina",
      "SD" => "South Dakota", "TN" => "Tennessee", "TX" => "Texas",
      "UT" => "Utah", "VT" => "Vermont", "VA" => "Virginia", "WA" => "Washington",
      "WV" => "West Virginia", "WI" => "Wisconsin", "WY" => "Wyoming"
    }
  )
end
