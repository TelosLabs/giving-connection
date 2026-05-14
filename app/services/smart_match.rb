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

  # Shared upper bound for any text we hand to the BGE embedding service.
  # Referenced by UserIntent#to_embedding_text and Organization#smart_match_text
  # so both producers stay aligned with the same character budget.
  EMBEDDING_TEXT_MAX_LENGTH = 1500
end
