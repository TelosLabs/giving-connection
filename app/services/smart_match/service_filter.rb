# frozen_string_literal: true

module SmartMatch
  # "Looking for a specific service?" -- the results page's optional refinement.
  #
  # Services used to be a quiz question. It tested badly: most people do not
  # know what a "service" is in this vocabulary, and being asked to name one
  # before seeing any results added friction for everybody to serve the
  # minority who arrive knowing exactly what they need. So it moved here, after
  # the results, where the need is concrete -- someone looking at six food
  # banks and thinking "I actually need eviction help" can say so.
  #
  # It is a FILTER, not a signal. Scoring, ranking and the embedding layer never
  # see it (config/smart_match_scoring.yml deliberately has no services
  # question); this only narrows which of the already-ranked matches are shown,
  # so nothing a user does here can reorder or re-weight the results.
  #
  # Options come from the services the matched organizations actually offer,
  # not from the full ~274-name vocabulary. Two reasons: the list stays short
  # enough to scan, and every option leads somewhere -- selecting one can never
  # empty the page.
  class ServiceFilter
    # Selections are OR'd (an organization qualifies by offering ANY of them),
    # so the count beside each option is also the floor for what a click leaves
    # on screen.
    Option = Struct.new(:name, :count, keyword_init: true)

    attr_reader :pool

    # pool: the submission's full OrganizationMatch relation, unfiltered.
    # requested: whatever came in on params[:services].
    def initialize(pool:, requested: nil)
      @pool = pool
      @requested = Array(requested).map { |name| name.to_s.strip }.compact_blank.uniq
    end

    # The requested services that are really on offer. Intersecting with the
    # available options means a stale or hand-edited URL degrades to showing
    # more rather than to an empty page.
    def selected
      @selected ||= @requested & options.values.flatten.map(&:name)
    end

    def active? = selected.any?

    # Worth rendering at all? One lone option can only ever narrow the page to
    # itself, which is not a choice.
    def available? = options.values.sum(&:size) > 1

    # {cause_name => [Option, ...]}, causes in the platform's own curated order
    # and services within a cause commonest first, so the ones most likely to
    # be wanted are nearest the top.
    def options
      @options ||= begin
        by_cause = counts_by_cause_and_service.group_by { |(cause, _service), _count| cause }
        curated = Organizations::Constants::CAUSES_AND_SERVICES.keys

        # A cause the curated list has never heard of still gets shown, after
        # the known ones. Dropping it would silently hide real services if the
        # constant and the causes table ever drift apart.
        ordered = curated & by_cause.keys
        ordered += (by_cause.keys - curated).sort

        ordered.index_with { |cause| options_for(by_cause[cause]) }
      end
    end

    # The pool narrowed to organizations offering at least one selected
    # service. Returns the pool untouched when nothing is selected, so the
    # unfiltered page costs no extra query.
    def matches
      return pool unless active?

      pool.where(organization_id: organization_ids_offering(selected))
    end

    private

    def options_for(entries)
      entries
        .map { |(_cause, service), count| Option.new(name: service, count: count) }
        .sort_by { |option| [-option.count, option.name] }
    end

    # {[cause_name, service_name] => organizations offering it}, over the whole
    # pool rather than the current page: the option list must not shrink as the
    # user pages through results.
    #
    # COUNT(DISTINCT organization_id) because a service tagged on three of an
    # organization's locations is still one organization.
    def counts_by_cause_and_service
      @counts_by_cause_and_service ||= Service
        .joins(:cause, :locations)
        .where(locations: {organization_id: pool_organization_ids})
        .group("causes.name", "services.name")
        .distinct
        .count("locations.organization_id")
    end

    def organization_ids_offering(names)
      Location
        .where(organization_id: pool_organization_ids)
        .joins(:services)
        .where(services: {name: names})
        .select(:organization_id)
    end

    def pool_organization_ids
      @pool_organization_ids ||= pool.pluck(:organization_id)
    end
  end
end
