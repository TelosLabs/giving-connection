# frozen_string_literal: true

module SmartMatch
  # Rolls the per-organization criteria in OrganizationMatch#score_breakdown up
  # into one list for the results page's "how we matched you" panel.
  #
  # The panel exists because most capability fields ship empty and fill in only
  # as organizations update their profiles
  # (docs/smart-match-scoring/06-phase-5-fields.md). Without it, a user who
  # asked for wheelchair-accessible services just sees three results and has no
  # way to know whether any of them are accessible, or whether nobody has said.
  #
  # Each entry reports how many of the shown matches satisfy the criterion, so
  # "1 of 3" is distinguishable from "none" and from "nobody has told us".
  class CriteriaSummary < ApplicationService
    # Personal Details are scored (the client's CSV assigns them a weight on
    # the Find Help path) but deliberately NOT shown in this panel.
    #
    # Displaying "Race or ethnicity: Black or African American ✕" reads as
    # though results were filtered by the user's race or gender, which is not
    # what happens -- the weight nudges organizations that name a matching
    # population served, at the lowest weight in the whole sheet. Showing it
    # would imply these organizations are for certain races or genders only.
    #
    # Hidden here, in the display layer, rather than in RuleScorer: the scoring
    # behaviour the CSV specifies is unchanged, only what we put in front of
    # the user.
    HIDDEN_QUESTIONS = %w[age_range gender_identity race_ethnicity].freeze

    Criterion = Struct.new(:question, :answer, :met_count, :partial_count, :unknown_count,
      :total, :grouped, :matched_count, :selected_count, keyword_init: true) do
      def all_met? = met_count == total

      # Counts toward "matched" in the headline. A criterion one match fully
      # meets, or that several meet in part, is not a failure.
      def matched? = met_count.positive? || partial_count.positive?

      # Nobody said no -- they simply have not published the information. Worth
      # separating from a flat "no": the user may still want to call and ask.
      def unknown? = !matched? && unknown_count == total

      def status
        return "met" if all_met?
        return "partial" if matched?
        return "unknown" if unknown?

        "unmet"
      end

      # Proportional questions (services) report how many of the user's own
      # selections matched, which is far more useful than how many of the three
      # shown organizations did.
      def detail? = grouped && selected_count.to_i.positive?
    end

    attr_reader :matches

    def initialize(matches:)
      @matches = matches
    end

    def call
      return [] if matches.blank?

      tally.map do |(question, answer), counts|
        Criterion.new(
          question: question,
          answer: answer,
          met_count: counts[:met],
          partial_count: counts[:partial],
          unknown_count: counts[:unknown],
          total: matches.size,
          grouped: counts[:grouped],
          # Best showing across the displayed matches -- "2 of 4 services"
          # means at least one organization covered two of them.
          matched_count: counts[:matched_count],
          selected_count: counts[:selected_count]
        )
      end
    end

    private

    # Preserves the order criteria were recorded in, which follows the quiz's
    # own question order -- so the panel reads in the order the user answered.
    def tally
      matches.each_with_object({}) do |match, acc|
        criteria_for(match).each do |criterion|
          next if HIDDEN_QUESTIONS.include?(criterion["question"])

          key = [criterion["question"], criterion["answer"]]
          acc[key] ||= {met: 0, partial: 0, unknown: 0, grouped: false, matched_count: 0, selected_count: 0}
          acc[key][:met] += 1 if criterion["status"] == RuleScorer::MET
          acc[key][:partial] += 1 if criterion["status"] == RuleScorer::PARTIAL
          acc[key][:unknown] += 1 if criterion["status"] == RuleScorer::UNKNOWN

          next unless criterion["grouped"]

          acc[key][:grouped] = true
          acc[key][:selected_count] = criterion["selected_count"].to_i
          acc[key][:matched_count] =
            [acc[key][:matched_count], criterion["matched_count"].to_i].max
        end
      end
    end

    # score_breakdown is jsonb, so keys come back as strings. Matches persisted
    # before this shipped have no criteria key at all.
    def criteria_for(match)
      Array(match.score_breakdown&.dig("criteria"))
    end
  end
end
