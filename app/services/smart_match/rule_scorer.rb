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
    # Fields that are a plain capability check on the organization rather than
    # a preset lookup: present/true scores, absent does not.
    BOOLEAN_FIELDS = {
      "donation_link" => ->(org) { org.donation_link.present? },
      "volunteer_availability" => ->(org) { org.volunteer_availability? }
    }.freeze

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
        next unless hit

        contribution = hit["weight"] * group[:multiplier]
        earned += contribution
        matched << trace_entry(group, hit, contribution)
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
          rules.reject { |rule| rule["requires_field"] }
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

    def rule_matches?(rule, answer)
      field = rule["field"]
      return BOOLEAN_FIELDS.fetch(field).call(organization) if BOOLEAN_FIELDS.key?(field)

      case rule["match"]
      when "prefix" then organization_values(field).any? { |value| value.start_with?(rule["preset"]) }
      when "answer" then organization_values(field).include?(answer)
      when "cause_service" then organization_values(field).intersect?(services_for_cause(answer))
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
      else []
      end
    end

    # The services the client's spec treats as belonging to a selected cause.
    # Read from the constant rather than the services table so the mapping
    # matches the vocabulary the scoring sheet was written against.
    def services_for_cause(cause_name)
      Organizations::Constants::CAUSES_AND_SERVICES.fetch(cause_name, [])
    end

    def trace_entry(group, rule, contribution)
      {
        question: group[:session_key],
        answer: group[:answer],
        field: rule["field"],
        preset: rule["preset"] || rule["match"] || rule["field"],
        weight: rule["weight"],
        multiplier: group[:multiplier],
        contribution: contribution.round(2)
      }
    end

    def answers
      @answers ||= user_intent.answers_by_key
    end

    def scoring_rules
      SmartMatch::SCORING_RULES
    end
  end
end
