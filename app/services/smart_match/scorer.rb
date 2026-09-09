# frozen_string_literal: true

module SmartMatch
  class Scorer < ApplicationService
    # Cap on the itemized rule trace persisted into
    # OrganizationMatch#score_breakdown. A broad multi-select answer set can
    # produce dozens of matches; the jsonb column doesn't need all of them to
    # explain a result.
    MAX_TRACE_ENTRIES = 12

    attr_reader :candidates, :user_intent

    def initialize(candidates:, user_intent:)
      @candidates = candidates
      @user_intent = user_intent
    end

    def call
      candidates.map { |c| score_candidate(c) }.sort_by { |r| -r[:score] }
    end

    private

    def score_candidate(candidate)
      organization = candidate[:organization_embedding].organization

      dense = dense_score(candidate[:cosine_distance])
      attribute = attribute_bonus(organization)
      distance = distance_score(candidate[:distance_miles])
      rules = RuleScorer.call(organization: organization, user_intent: user_intent)

      total = (weight("embedding_similarity") * dense) +
        (weight("rule_score") * rules[:score]) +
        (weight("attribute_bonus") * attribute) +
        (weight("distance") * distance)

      {
        organization: organization,
        score: total.round(4),
        score_breakdown: {
          dense_similarity: dense.round(4),
          rule_score: rules[:score],
          attribute_bonus: attribute.round(4),
          distance_score: distance.round(4),
          # Itemized so a result can be explained, not just ranked. Trimmed
          # because this is persisted per match; the highest-contributing
          # rules are the ones worth showing.
          #
          # Ties are broken on question/answer/field so the persisted order is
          # deterministic. Ruby's sort_by is not stable, and equal-contribution
          # entries are common (a 5-weight population and a 5-weight cause hit
          # the same number), so sorting on contribution alone makes the stored
          # breakdown vary run to run for identical input.
          rule_matches: rules[:matched]
            .sort_by { |m| [-m[:contribution], m[:question], m[:answer], m[:field]] }
            .first(MAX_TRACE_ENTRIES),
          rule_points: {earned: rules[:earned], max: rules[:max]},
          # Every answer the user gave, with whether this organization meets
          # it. Drives the "how we matched you" panel on the results page --
          # unlike rule_matches it is NOT trimmed, because a criterion missing
          # from the list would read as "we ignored what you asked for".
          criteria: rules[:criteria]
        }
      }
    end

    def dense_score(cosine_distance)
      [1.0 - cosine_distance, 0.0].max
    end

    def attribute_bonus(organization)
      total_weight = attribute_weights.values.sum.to_f
      return 0.0 if total_weight.zero?

      earned = 0.0
      earned += attribute_weights["cause_match"] if causes_match?(organization)
      earned += attribute_weights["beneficiary_match"] if beneficiary_match?(organization)
      earned += attribute_weights["scope_match"] if scope_match?(organization)
      earned += attribute_weights["service_match"] if service_match?(organization)

      earned / total_weight
    end

    def causes_match?(organization)
      # Use map(&:name) so preloaded :causes association is served from the
      # ActiveRecord cache instead of issuing a fresh SELECT per candidate.
      org_causes = Set.new(organization.causes.map(&:name))
      selected_causes.intersect?(org_causes)
    end

    def beneficiary_match?(organization)
      return false if user_intent.prefs_selected.blank?

      org_beneficiaries = Set.new(organization.beneficiary_subcategories.map(&:name))
      user_intent.prefs_selected.any? { |p| org_beneficiaries.include?(p) }
    end

    def scope_match?(organization)
      scope = organization.scope_of_work
      return false if scope.blank?

      case user_intent.location_scope
      when "national" then %w[National International].include?(scope)
      when "international" then scope == "International"
      else local_scope_match?(scope)
      end
    end

    # Local (city-based) search: the willingness-to-travel bucket decides which
    # org scopes are a good fit.
    def local_scope_match?(scope)
      bucket = user_intent.travel_bucket
      return false if bucket.blank?

      case bucket
      when "statewide" then %w[National International].include?(scope)
      when "far" then true
      else scope != "International"
      end
    end

    def service_match?(organization)
      return false if user_intent.prefs_selected.blank?

      org_services = Set.new(organization.locations.flat_map { |l| l.services.map(&:name) })
      user_intent.prefs_selected.any? { |p| org_services.include?(p) }
    end

    def selected_causes
      @selected_causes ||= Set.new(Array(user_intent.causes_selected))
    end

    def weights
      @weights ||= SmartMatch::MATCHING_RULES["scoring"]["weights"]
    end

    # Defaults to 0 so a weight absent from matching_rules.yml disables that
    # term rather than raising mid-request.
    def weight(name)
      weights.fetch(name, 0).to_f
    end

    def attribute_weights
      @attribute_weights ||= SmartMatch::MATCHING_RULES["attribute_weights"]
    end

    def distance_score(distance_miles)
      return 1.0 if distance_miles.nil? || distance_miles <= 5

      [1.0 - (distance_miles / 100.0), 0.0].max
    end
  end
end
