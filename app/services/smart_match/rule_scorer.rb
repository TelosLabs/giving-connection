# frozen_string_literal: true

module SmartMatch
  # Scores one organization against one set of quiz answers using the client's
  # explicit weighting table in config/smart_match_scoring.yml.
  #
  # Returns a normalized 0..1 score plus an itemized trace of what matched, so
  # a result can be explained rather than just ranked. The trace lands in
  # OrganizationMatch#score_breakdown.
  #
  # The two rules that are easy to get wrong, both documented at length in
  # docs/smart-match-scoring/02-spec-interpretation.md:
  #
  #   1. Within one (answer, field) group only the HIGHEST matching weight
  #      counts. Summing would let an org win by tag count.
  #   2. The total is divided by the maximum achievable for *this user's*
  #      answers, not a global constant. Without it, users who tick more boxes
  #      score higher regardless of fit.
  #
  # Rules whose backing nonprofit field does not exist yet (requires_field) are
  # skipped from both sides of that ratio -- users are never penalised for data
  # the platform has not collected.
  class RuleScorer < ApplicationService
    # The language the platform assumes without being told. Used by the
    # "Spanish or another language available" preference, which asks for any
    # language beyond this one rather than naming a specific alternative.
    DEFAULT_LANGUAGE = "English"

    # Fields that are a plain capability check rather than a preset lookup.
    #
    # A lambda returns true (scores), false (does not score), or nil (UNKNOWN
    # -- the organization has never been asked). nil is not the same as false:
    # see #each_answer_group, which drops unknown rules from the achievable
    # maximum as well as from the earned score, so an organization with no data
    # is not penalised and the user's normalized score doesn't move.
    #
    # That distinction is what lets these fields ship with almost no data.
    BOOLEAN_FIELDS = {
      # Pre-existing columns. Both are non-nullable, so absence really does
      # mean "no" for them.
      "donation_link" => ->(org) { org.donation_link.present? },
      "volunteer_availability" => ->(org) { org.volunteer_availability? },

      # Organization-level Smart Match fields. Nullable -- nil is unknown.
      "free_or_sliding_scale" => ->(org) { org.free_or_sliding_scale },
      "no_id_required" => ->(org) { org.no_id_required },
      "lgbtqia_affirming" => ->(org) { org.lgbtqia_affirming },
      "specific_project_giving" => ->(org) { org.specific_project_giving },
      "accepts_in_kind" => ->(org) { org.accepts_in_kind },
      "recurring_giving" => ->(org) { org.recurring_giving },
      "fundraising_events" => ->(org) { org.fundraising_events },
      "partnership_opportunities" => ->(org) { org.partnership_opportunities },

      # Location-level. True if ANY location qualifies, unknown only when no
      # location has been answered either way -- an organization with one
      # audited-inaccessible site and one unaudited site is a definite "we
      # don't know of an accessible site", not an unknown.
      "wheelchair_accessible" => ->(org) { any_location(org, :wheelchair_accessible) },
      "remote_services" => ->(org) { any_location(org, :remote_services) }
    }.freeze

    # true if any location says yes; nil if every location is unanswered;
    # false if at least one answered and none said yes.
    def self.any_location(organization, attribute)
      values = organization.locations.map { |l| l.public_send(attribute) }
      return true if values.any?(true)
      return nil if values.all?(&:nil?)

      false
    end

    attr_reader :organization, :user_intent

    def initialize(organization:, user_intent:)
      @organization = organization
      @user_intent = user_intent
    end

    def call
      earned = 0.0
      maximum = 0.0
      matched = []

      each_answer_group do |group|
        best = group[:rules].max_by { |rule| rule["weight"] }
        maximum += best["weight"] * group[:multiplier]

        hit = group[:rules].select { |rule| rule_matches?(rule, group[:answer]) }
          .max_by { |rule| rule["weight"] }

        # No exact match, but an organization that serves the general
        # population still serves this user -- credit it partially rather than
        # scoring it zero.
        via_general_population = hit.nil? && general_population_match?(best)
        hit = best if via_general_population
        next unless hit

        credit = via_general_population ? general_population_credit : 1.0
        contribution = hit["weight"] * group[:multiplier] * credit
        earned += contribution
        matched << trace_entry(group, hit, contribution, general_population: via_general_population)
      end

      {
        score: maximum.zero? ? 0.0 : (earned / maximum).round(4),
        earned: earned.round(2),
        max: maximum.round(2),
        matched: matched
      }
    end

    private

    # Yields one hash per (answer, field) group -- the unit the "highest weight
    # wins" rule applies to. Groups with no scorable rules (every rule blocked
    # on a missing field) are skipped entirely so they affect neither side of
    # the normalization.
    def each_answer_group
      applicable_questions.each do |session_key, question|
        answers.fetch(session_key, []).each do |answer|
          spec = answer_spec(question, answer)
          next if spec.nil?

          rules, multiplier = spec
          rules.reject { |rule| rule["requires_field"] || unknown?(rule) }
            .group_by { |rule| rule["field"] }
            .each_value do |field_rules|
              yield(
                session_key: session_key,
                answer: answer,
                multiplier: multiplier,
                rules: field_rules
              )
            end
        end
      end
    end

    # [[session_key, question], ...] for this user's path.
    #
    # A question entry is normally keyed by its session answer key. Where two
    # paths ask the same question with different weights, the second entry
    # carries an explicit session_key (e.g. "causes_donor" reads "causes").
    def applicable_questions
      scoring_rules.fetch("questions", {}).filter_map do |key, question|
        next unless question.fetch("paths", []).include?(user_intent.user_type.to_s)

        [question["session_key"] || key, question]
      end
    end

    # Returns [rules, multiplier] or nil when the answer has no entry.
    #
    # "*" is the catch-all used by the cause questions, where the answer is
    # itself a cause name and cannot be enumerated. An explicitly-listed answer
    # always wins over it, which is how "none" opts out.
    def answer_spec(question, answer)
      answer_map = question.fetch("answers", {})
      entry = answer_map.key?(answer) ? answer_map[answer] : answer_map["*"]
      return nil if entry.nil?

      if entry.is_a?(Hash)
        [Array(entry["rules"]), entry.fetch("multiplier", question["multiplier"]).to_f]
      else
        [Array(entry), question["multiplier"].to_f]
      end
    end

    # A capability the organization has simply never been asked about. Such a
    # rule is dropped from the achievable maximum as well as from the earned
    # score, so missing data neither helps nor hurts. Preset fields (cause,
    # population, ...) have no unknown state: an org either carries the tag or
    # it doesn't.
    def unknown?(rule)
      return organization.languages.blank? if rule["field"] == "languages"

      BOOLEAN_FIELDS.key?(rule["field"]) && boolean_value(rule["field"]).nil?
    end

    def boolean_value(field)
      @boolean_values ||= {}
      return @boolean_values[field] if @boolean_values.key?(field)

      @boolean_values[field] = BOOLEAN_FIELDS.fetch(field).call(organization)
    end

    # An organization flagged general_population_serving records no
    # beneficiary subcategories at all -- the flag exists so it doesn't have
    # to enumerate them. All 54 such organizations in production have zero
    # populations, so every population rule scored them 0 no matter how well
    # they fit: an org that serves everyone, including this user, ranked below
    # one that ticked a matching box.
    #
    # Partial credit rather than a full match. "We serve everyone" is a genuine
    # fit but a weaker signal than "we specialise in your population", so the
    # rule's weight is scaled by general_population_credit in matching_rules.yml
    # rather than counted in full.
    def general_population_match?(rule)
      rule["field"] == "population" && organization.general_population_serving?
    end

    def rule_matches?(rule, answer)
      field = rule["field"]
      return boolean_value(field) == true if BOOLEAN_FIELDS.key?(field)

      case rule["match"]
      when "prefix" then organization_values(field).any? { |value| value.start_with?(rule["preset"]) }
      when "answer" then organization_values(field).include?(answer)
      when "cause_service" then organization_values(field).intersect?(services_for_cause(answer))
      # "Spanish or another language available" doesn't say which language, so
      # any language beyond the assumed default satisfies it.
      when "non_default_language" then organization_values(field).any? { |l| l != DEFAULT_LANGUAGE }
      else organization_values(field).include?(rule["preset"])
      end
    end

    # Preloaded by SimilarityQuery#base_scope -- map(&:name) rather than
    # pluck so the association cache is used instead of a query per candidate.
    def organization_values(field)
      @organization_values ||= {}
      @organization_values[field] ||= case field
      when "population" then organization.beneficiary_subcategories.map(&:name)
      when "cause" then organization.causes.map(&:name)
      when "service" then organization.locations.flat_map { |l| l.services.map(&:name) }.uniq
      when "ntee" then [organization.irs_ntee_code].compact
      when "languages" then Array(organization.languages)
      else []
      end
    end

    # The services the client's spec treats as belonging to a selected cause.
    # Read from the constant rather than the services table so the mapping
    # matches the vocabulary the scoring sheet was written against.
    def services_for_cause(cause_name)
      Organizations::Constants::CAUSES_AND_SERVICES.fetch(cause_name, [])
    end

    def trace_entry(group, rule, contribution, general_population: false)
      entry = {
        question: group[:session_key],
        answer: group[:answer],
        field: rule["field"],
        preset: rule["preset"] || rule["match"] || rule["field"],
        weight: rule["weight"],
        multiplier: group[:multiplier],
        contribution: contribution.round(2)
      }
      # Flagged so a result reading "matched Seniors" can be distinguished from
      # "serves everyone, including seniors".
      general_population ? entry.merge(via: "general_population_serving") : entry
    end

    def general_population_credit
      SmartMatch::MATCHING_RULES.dig("scoring", "general_population_credit") || 0.5
    end

    def answers
      @answers ||= user_intent.answers_by_key
    end

    def scoring_rules
      SmartMatch::SCORING_RULES
    end
  end
end
