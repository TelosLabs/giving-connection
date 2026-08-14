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
    # see #evaluate, which drops unknown rules from the achievable
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

    # Status of one thing the user asked for, against this organization.
    #   met      the organization satisfies it
    #   unmet    the organization was asked and does not satisfy it
    #   unknown  the organization has never recorded an answer either way
    #
    # `unknown` is not a softer `unmet`. Most capability fields ship empty and
    # fill in only as organizations update their profiles, so telling a
    # wheelchair user "this organization has not told us" is materially
    # different from "this organization is not accessible".
    MET = "met"
    UNMET = "unmet"
    UNKNOWN = "unknown"

    def call
      @earned = 0.0
      @maximum = 0.0
      @matched = []
      @criteria = []

      each_question do |session_key, question, given|
        given.each { |answer| score_independent_answer(session_key, question, answer) }
      end

      {
        score: @maximum.zero? ? 0.0 : (@earned / @maximum).round(4),
        earned: @earned.round(2),
        max: @maximum.round(2),
        matched: @matched,
        criteria: @criteria
      }
    end

    private

    # Yields once per question the user answered, with the answers they gave.
    #
    # Answers with an empty rule list are dropped: an explicit "scores nothing"
    # entry (escape hatches like "No preference") is not something the user
    # asked for, so it is neither scored nor reported as a criterion.
    def each_question
      applicable_questions.each do |session_key, question|
        given = answers.fetch(session_key, []).select do |answer|
          spec = answer_spec(question, answer)
          spec&.first&.any?
        end
        next if given.empty?

        yield(session_key, question, given)
      end
    end

    # One answer, scored on its own terms: each of its field groups adds its
    # full weight to the achievable maximum.
    def score_independent_answer(session_key, question, answer)
      result = evaluate(session_key, question, answer)

      if result[:unknown]
        @criteria << {question: session_key, answer: answer, status: UNKNOWN}
        return
      end

      @earned += result[:earned]
      @maximum += result[:maximum]
      @matched.concat(result[:matched])
      @criteria << {question: session_key, answer: answer, status: result[:met] ? MET : UNMET}
    end

    # Scores one answer without touching the running totals, so the caller can
    # decide whether to bank it whole.
    def evaluate(session_key, question, answer)
      rules, multiplier = answer_spec(question, answer)
      scorable = rules.reject { |rule| rule["requires_field"] || unknown?(rule) }

      # Every rule is blocked on data the organization has never supplied. It
      # affects neither side of the ratio, but the user still asked for it.
      return {unknown: true, met: false, earned: 0.0, maximum: 0.0, matched: []} if scorable.empty?

      earned = 0.0
      maximum = 0.0
      matched = []
      met = false

      scorable.group_by { |rule| rule["field"] }.each_value do |field_rules|
        group = {session_key: session_key, answer: answer, multiplier: multiplier, rules: field_rules}
        best = field_rules.max_by { |rule| rule["weight"] }
        maximum += best["weight"] * multiplier

        hit = field_rules.select { |rule| rule_matches?(rule, answer) }
          .max_by { |rule| rule["weight"] }

        # No exact match, but an organization that serves the general
        # population still serves this user -- credit it partially rather than
        # scoring it zero.
        via_general_population = hit.nil? && general_population_match?(best)
        hit = best if via_general_population
        next unless hit

        met = true
        credit = via_general_population ? general_population_credit : 1.0
        contribution = hit["weight"] * multiplier * credit
        earned += contribution
        matched << trace_entry(group, hit, contribution, general_population: via_general_population)
      end

      {unknown: false, met: met, earned: earned, maximum: maximum, matched: matched}
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
      field = rule["field"]
      # A blank vocabulary column is "not yet answered", not "offers none" --
      # an organization that records no volunteer formats has not told us it
      # runs no volunteer programme.
      return organization_values(field).blank? if VOCABULARY_FIELDS.include?(field)

      BOOLEAN_FIELDS.key?(field) && boolean_value(field).nil?
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
      # The answer and the organization's value come from different
      # vocabularies -- see ANSWER_VOCABULARY.
      when "answer_vocabulary" then organization_values(field).intersect?(vocabulary_for(field, answer))
      else organization_values(field).include?(rule["preset"])
      end
    end

    def vocabulary_for(field, answer)
      ANSWER_VOCABULARY.dig(field, answer) || []
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
      when "volunteer_format" then [organization.volunteer_format].compact
      when "volunteer_frequency" then Array(organization.volunteer_frequency)
      when "leadership_attributes" then Array(organization.leadership_attributes)
      else []
      end
    end

    # Fields whose value is a vocabulary the organization chose from, where
    # "not yet answered" is a blank column rather than a false boolean.
    VOCABULARY_FIELDS = %w[languages volunteer_format volunteer_frequency leadership_attributes].freeze

    # Maps a quiz answer to the organization-side vocabulary values that
    # satisfy it. The two vocabularies are deliberately different: the user is
    # asked what they want, the organization records what it offers, and the
    # words don't line up one-to-one.
    ANSWER_VOCABULARY = {
      # "Only in-person" is satisfied by an in-person OR hybrid programme.
      "volunteer_format" => {
        "in_person" => ["In person", "Hybrid"],
        "remote" => ["Remote", "Hybrid"],
        "both" => ["In person", "Remote", "Hybrid"]
      },
      "volunteer_frequency" => {
        "one_time" => ["One-time", "Event-based"],
        "few_hours" => ["Weekly"],
        "ongoing" => ["Ongoing"]
      },
      # The quiz asks a single "Women- or BIPOC-led" question, so either
      # attribute satisfies it.
      "leadership_attributes" => {
        "women_bipoc_led" => ["Women-led", "BIPOC-led"]
      }
    }.freeze

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
