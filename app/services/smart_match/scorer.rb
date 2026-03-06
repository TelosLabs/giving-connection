# frozen_string_literal: true

module SmartMatch
  class Scorer < ApplicationService
    attr_reader :candidates, :user_intent

    def initialize(candidates:, user_intent:)
      @candidates = candidates
      @user_intent = user_intent
    end

    def call
      scored = candidates.map { |candidate| score_candidate(candidate) }
      scored.sort_by { |r| -r[:score] }
    end

    private

    def score_candidate(candidate)
      dense = dense_score(candidate[:cosine_distance])
      attribute = attribute_bonus(candidate[:organization_embedding].organization)
      distance = distance_score(candidate[:distance_miles])

      total = (weights[:embedding_similarity] * dense) +
        (weights[:attribute_bonus] * attribute) +
        (weights[:distance] * distance)

      {
        organization: candidate[:organization_embedding].organization,
        score: total.round(4),
        score_breakdown: {
          dense_similarity: dense.round(4),
          attribute_bonus: attribute.round(4),
          distance_score: distance.round(4)
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
      earned += attribute_weights[:cause_match] if causes_match?(organization)
      earned += attribute_weights[:beneficiary_match] if beneficiary_match?(organization)
      earned += attribute_weights[:scope_match] if scope_match?(organization)
      earned += attribute_weights[:service_match] if service_match?(organization)

      earned / total_weight
    end

    def causes_match?(organization)
      selected = Set.new(Array(user_intent.causes_selected))
      org_causes = Set.new(organization.causes.pluck(:name))
      selected.intersect?(org_causes)
    end

    def beneficiary_match?(organization)
      prefs = Array(user_intent.prefs_selected)
      return false if prefs.empty?

      org_beneficiaries = Set.new(organization.beneficiary_subcategories.pluck(:name))
      prefs.any? { |pref| org_beneficiaries.include?(pref) }
    end

    def scope_match?(organization)
      bucket = user_intent.travel_bucket
      scope = organization.scope_of_work
      return false if bucket.blank? || scope.blank?

      case bucket
      when "statewide" then %w[National International].include?(scope)
      when "far" then true
      else scope != "International"
      end
    end

    def service_match?(organization)
      prefs = Array(user_intent.prefs_selected)
      return false if prefs.empty?

      org_services = Set.new(organization.locations.flat_map { |l| l.services.pluck(:name) })
      prefs.any? { |pref| org_services.include?(pref) }
    end

    def weights
      @weights ||= begin
        w = matching_rules["scoring"]["weights"]
        {
          embedding_similarity: w["embedding_similarity"],
          attribute_bonus: w["attribute_bonus"],
          distance: w["distance"]
        }
      end
    end

    def attribute_weights
      @attribute_weights ||= begin
        w = matching_rules["attribute_weights"]
        {
          cause_match: w["cause_match"],
          beneficiary_match: w["beneficiary_match"],
          scope_match: w["scope_match"],
          service_match: w["service_match"]
        }
      end
    end

    def distance_score(distance_miles)
      return 1.0 if distance_miles.nil?
      return 1.0 if distance_miles <= 5

      [1.0 - (distance_miles / 100.0), 0.0].max
    end

    def matching_rules
      @matching_rules ||= YAML.load_file(Rails.root.join("config", "matching_rules.yml"))
    end
  end
end
