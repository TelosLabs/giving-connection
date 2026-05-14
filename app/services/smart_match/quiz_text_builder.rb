# frozen_string_literal: true

module SmartMatch
  class QuizTextBuilder < ApplicationService
    MAX_LENGTH = 1500
    # Reserve up to this many characters for the user's free-text input so it
    # is never truncated away by long cause / synonym lists.
    LANGUAGE_INPUT_BUDGET = 500
    PRIMARY_CAUSE_WEIGHT = 3

    attr_reader :user_intent

    def initialize(user_intent:)
      @user_intent = user_intent
    end

    def call
      free_text = Array(user_intent.language_input).join(" ").strip
      free_text = free_text.truncate(LANGUAGE_INPUT_BUDGET) if free_text.length > LANGUAGE_INPUT_BUDGET

      remaining_budget = MAX_LENGTH - (free_text.empty? ? 0 : free_text.length + 3) # " | " separator

      structured_parts = []
      structured_parts.concat(weighted_causes)
      structured_parts << location_text if location_text.present?
      structured_parts.concat(preferences)

      structured_text = structured_parts.compact_blank.join(" | ").truncate([remaining_budget, 0].max)

      pieces = []
      pieces << free_text unless free_text.empty?
      pieces << structured_text unless structured_text.empty?
      pieces.join(" | ")
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
