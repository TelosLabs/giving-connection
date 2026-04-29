# frozen_string_literal: true

module SmartMatch
  class QuizTextBuilder < ApplicationService
    MAX_LENGTH = 1500
    PRIMARY_CAUSE_WEIGHT = 3

    attr_reader :user_intent

    def initialize(user_intent:)
      @user_intent = user_intent
    end

    def call
      parts = []
      parts.concat(weighted_causes)
      parts << location_text if location_text.present?
      parts.concat(preferences)

      parts.compact_blank.join(" | ").truncate(MAX_LENGTH)
    end

    private

    def weighted_causes
      causes = Array(user_intent.causes_selected)
      causes.flat_map { |cause| expand_cause(cause) * PRIMARY_CAUSE_WEIGHT }
    end

    def expand_cause(cause)
      mapping = cause_mappings[cause]
      return [cause] unless mapping

      synonyms = Array(mapping["synonyms"])
      [cause] + synonyms
    end

    def preferences
      Array(user_intent.prefs_selected).compact_blank
    end

    def location_text
      @location_text ||= [user_intent.city, user_intent.state]
        .map(&:presence).compact.join(", ")
    end

    def cause_mappings
      SmartMatch::Config.matching_rules.fetch("cause_mappings", {})
    end
  end
end
