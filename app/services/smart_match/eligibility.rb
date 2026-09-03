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

    # The travel-step answer labelled "Remote services only". The stored token
    # is `statewide` because the option's copy was rewritten without renaming
    # the value, and renaming it now would strand in-flight sessions and every
    # historical QuizSubmission. The label is the source of truth for what it
    # means; this constant is the one place that mapping is written down.
    REMOTE_ONLY_TRAVEL_BUCKET = "statewide"

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
        (remote_services_filter if wants_remote_only?),
        (volunteer_opportunities_filter if volunteer?),
        (donation_link_filter if wants_general_donation?)
      ].compact
    end

    # The client's spec makes this a hard requirement, but the backing field
    # ships empty and fills in only as organizations edit their profiles. As an
    # absolute filter that would hide every organization that simply hasn't
    # answered yet -- a wrong answer presented as a complete one. Relaxable
    # gives correct behaviour at any level of coverage: remote organizations
    # rank alone once enough have said yes, and until then the user is told
    # the search was broadened.
    def remote_services_filter
      [
        :remote_services,
        ->(scope) {
          scope.where(organization_id: Location.where(remote_services: true).select(:organization_id))
        }
      ]
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

    # The travel step's "Remote services only" answer. Its session token is
    # still `statewide` -- a leftover from an earlier copy revision, kept so
    # in-flight sessions don't break. See REMOTE_ONLY_TRAVEL_BUCKET.
    def wants_remote_only?
      service_seeker? && user_intent.travel_bucket.to_s == REMOTE_ONLY_TRAVEL_BUCKET
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
