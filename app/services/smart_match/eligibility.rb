# frozen_string_literal: true

module SmartMatch
  # Turns a UserIntent into the eligibility constraints applied during
  # retrieval, kept deliberately separate from ranking. The client's scoring
  # spec repeats "treat the filter separately from ranking score" on nearly
  # every row that has one -- an ineligible organization must not appear at
  # any score, and a merely-imperfect one must not be excluded.
  #
  # Two tiers, per the agreed filter policy
  # (docs/smart-match-scoring/03-findings-and-gaps.md):
  #
  #   required  - absolute. Never dropped. Showing a Nashville seeker an
  #               LA-only organization is a wrong answer, not a broad one.
  #   relaxable - dropped, as a set, when keeping them would starve the result
  #               list. The caller reports what it dropped so the UI can say
  #               the search was broadened.
  #
  # Answers that describe *preference* rather than *capability* -- causes,
  # self-description, donor communities, volunteer type -- are never filters.
  # They are scored by RuleScorer, where selecting more of them raises the
  # score of organizations matching more of them, rather than narrowing the
  # pool to organizations matching all of them.
  class Eligibility
    # Organizations that stay eligible for a *local* search because their
    # reach isn't geographically bounded -- someone in Nashville can still use
    # a national helpline. They are only *required* when the user explicitly
    # asks for nationwide.
    #
    # "National" only, deliberately. The client's spec says "nationwide
    # organizations remain eligible" and names Scope of Work = National.
    # "International" is a distinct scope for globally-focused work (relief,
    # foreign policy), and folding it into every local search would add orgs
    # that are rarely the right answer for someone seeking local help.
    # Explicit nationwide searches still broaden into International when too
    # few National orgs match -- see SimilarityQuery#scoped_results.
    NATIONWIDE_SCOPES = %w[National].freeze

    attr_reader :user_intent

    def initialize(user_intent:)
      @user_intent = user_intent
    end

    # Tier 1. Applied unconditionally.
    def apply_required(scope)
      service_seeker? ? with_service_availability(scope) : scope
    end

    # Tier 2. Applied first, dropped together if the result set is too thin.
    def apply_relaxable(scope)
      relaxable.reduce(scope) { |acc, (_label, filter)| filter.call(acc) }
    end

    # Labels for whatever apply_relaxable would constrain, so the caller can
    # report which filters it gave up on.
    def relaxable_labels
      relaxable.map(&:first)
    end

    def relaxable?
      relaxable.any?
    end

    private

    # [[label, ->(scope) { ... }], ...]
    #
    # Only ever one entry today (the paths are mutually exclusive), so dropping
    # them as a set is equivalent to dropping them one at a time. If Tier 4
    # preference filters land here once their fields exist, revisit: those
    # should be shed progressively, lowest CSV weight first.
    def relaxable
      @relaxable ||= [
        (volunteer_opportunities_filter if volunteer?),
        (donation_link_filter if wants_general_donation?)
      ].compact
    end

    # 61% of production organizations carry volunteer_availability, so this is
    # a real filter rather than a data-absence trap. volunteer_link is OR-ed in
    # for completeness -- in production it is currently a strict subset of the
    # flag, so it adds nothing today, but it keeps the filter honest if the two
    # ever diverge.
    def volunteer_opportunities_filter
      [
        :volunteer_opportunities,
        ->(scope) {
          scope.where(
            organization_id: Organization.where(volunteer_availability: true)
              .or(Organization.where.not(volunteer_link: [nil, ""]))
              .select(:id)
          )
        }
      ]
    end

    def donation_link_filter
      [
        :donation_link,
        ->(scope) {
          scope.where(organization_id: Organization.where.not(donation_link: [nil, ""]).select(:id))
        }
      ]
    end

    # "Any location offers services", not "the main location does". An
    # organization running services from a branch while its head office is
    # administrative still offers services.
    def with_service_availability(scope)
      scope.where(organization_id: Location.where(offer_services: true).select(:organization_id))
    end

    def service_seeker?
      user_intent.user_type.to_s == "service_seeker"
    end

    def volunteer?
      user_intent.user_type.to_s == "volunteer"
    end

    # Only the "general donation" answer implies the user needs a working
    # donation link. Someone donating goods, or just exploring, does not.
    def wants_general_donation?
      user_intent.user_type.to_s == "donor" &&
        Array(user_intent.donation_style).include?("general_donation")
    end
  end
end
