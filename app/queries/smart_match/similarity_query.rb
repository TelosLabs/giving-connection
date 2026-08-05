# frozen_string_literal: true

module SmartMatch
  class SimilarityQuery
    EXPANSION_RADII = [5, 10, 25, 50].freeze
    # Fallback only. The live value is read from config/matching_rules.yml
    # (scoring.min_results) via #min_results; this constant is used when the key
    # is absent.
    MIN_RESULTS = 3
    MILES_TO_METERS = 1609.344

    NON_LOCAL_SCOPES = %w[national international].freeze

    # Candidates plus the eligibility filters that had to be dropped to find
    # them. `relaxed` drives the "we broadened your search" notice, so an empty
    # array means the results satisfy everything the user asked for.
    Result = Struct.new(:candidates, :relaxed, keyword_init: true) do
      def relaxed?
        relaxed.present?
      end
    end

    class << self
      def call(embedding:, state:, coordinates:, radius_miles: 5, location_scope: "local", user_intent: nil)
        eligibility = user_intent && Eligibility.new(user_intent: user_intent)

        # Try with every eligibility filter in place, then again without the
        # relaxable ones. Retrieval is otherwise identical, so the second pass
        # only ever widens.
        strict = retrieve(embedding, state, coordinates, radius_miles, location_scope, eligibility,
          relax: false, user_intent: user_intent)
        return Result.new(candidates: strict, relaxed: []) if sufficient?(strict) || eligibility.nil? || !eligibility.relaxable?

        relaxed = retrieve(embedding, state, coordinates, radius_miles, location_scope, eligibility,
          relax: true, user_intent: user_intent)
        return Result.new(candidates: strict, relaxed: []) if relaxed.size <= strict.size

        Result.new(candidates: relaxed, relaxed: eligibility.relaxable_labels)
      end

      private

      def retrieve(embedding, state, coordinates, radius_miles, location_scope, eligibility, relax:, user_intent: nil)
        scope = eligible_base(eligibility, relax: relax)

        # "Anywhere" outranks every other geographic signal, including a city
        # the donor named on a later step.
        return results_from(scope, embedding) if user_intent && !user_intent.geographic_filtering?

        return scoped_results(scope, embedding, location_scope) if NON_LOCAL_SCOPES.include?(location_scope.to_s)

        state_scope = filtered_scope(scope, state)

        return results_from(scope, embedding) if state_scope.none?

        # If we couldn't resolve coordinates, skip distance filtering entirely.
        return results_from(state_scope, embedding) if coordinates.nil?

        expansion_radii(radius_miles).each do |radius|
          candidates = distance_filtered(state_scope, coordinates, radius)
          next if candidates.none?

          results = results_from(candidates, embedding, coordinates)
          return results if results.size >= min_results
        end

        results_from(state_scope, embedding)
      end

      def eligible_base(eligibility, relax:)
        return base_scope if eligibility.nil?

        scope = eligibility.apply_required(base_scope)
        relax ? scope : eligibility.apply_relaxable(scope)
      end

      def sufficient?(results)
        results.size >= min_results
      end

      # Nationwide / international searches ignore geography and match on the
      # organization's scope_of_work instead. "National" broadens to also
      # include "International" if too few results are found (international
      # orgs commonly serve the US too); "international" stays strict.
      def scoped_results(scope, embedding, location_scope)
        primary_codes = (location_scope.to_s == "international") ? %w[International] : %w[National]
        results = results_from(scope_filtered(scope, primary_codes), embedding)

        return results if location_scope.to_s == "international" || results.size >= min_results

        broadened = results_from(scope_filtered(scope, %w[National International]), embedding)
        (broadened.size > results.size) ? broadened : results
      end

      def scope_filtered(scope, scope_codes)
        scope.where(organizations: {scope_of_work: scope_codes})
      end

      # Joins ALL locations, not just the main one.
      #
      # Restricting to main locations meant an organization was only ever
      # findable at its head office: a Nashville branch of a California-
      # headquartered organization was invisible to a Nashville search, and a
      # nearby branch was filtered out by the radius because the head office
      # was too far. That contradicted the eligibility filters, which read
      # "any location offers services".
      #
      # `distinct` collapses the extra rows the wider join produces.
      def base_scope
        OrganizationEmbedding
          .joins(organization: :locations)
          .includes(organization: [:causes, :beneficiary_subcategories, :tags, {locations: :services}])
          .merge(Location.joins(:organization).where(organizations: {active: true}))
          .distinct
      end

      # A local search is "organizations in this state, PLUS organizations
      # whose reach isn't geographically bounded at all".
      #
      # Nationwide organizations used to be invisible to local searchers: the
      # state predicate dropped any org without a location in that state, so a
      # national helpline never appeared for someone searching Nashville. The
      # client's spec calls for them on every location row, and they are only
      # *excluded* when the user picks a specific non-local scope.
      def filtered_scope(scope, state)
        code = state.to_s.upcase
        like = "%#{ActiveRecord::Base.sanitize_sql_like(state)}%"

        scope.where(
          # Prefer the structured state_code column (indexed, exact match).
          # Fall back to address ILIKE for locations not yet backfilled by
          # `rake smart_match:backfill_location_state_codes`.
          "locations.state_code = :code
             OR (locations.state_code IS NULL AND locations.address ILIKE :like)
             OR organizations.scope_of_work IN (:nationwide)",
          code: code, like: like, nationwide: Eligibility::NATIONWIDE_SCOPES
        )
      end

      # Nationwide organizations bypass the radius entirely -- their main
      # office's distance from the user says nothing about whether they can
      # help. Without this they'd be added by filtered_scope and then
      # immediately filtered back out by every radius pass.
      def distance_filtered(scope, coordinates, radius_miles)
        point = Geo.to_wkt(Geo.point(coordinates[:longitude], coordinates[:latitude]))
        scope.where(
          "ST_DWithin(locations.lonlat, :point, :distance)
             OR organizations.scope_of_work IN (:nationwide)",
          point: point,
          distance: radius_miles * MILES_TO_METERS,
          nationwide: Eligibility::NATIONWIDE_SCOPES
        )
      end

      def results_from(scope, embedding, coordinates = nil)
        scope
          .nearest_neighbors(:embedding, embedding, distance: "cosine")
          .limit(matching_rules["scoring"]["max_results"])
          .map { |oe| build_result(oe, coordinates) }
      end

      def build_result(org_embedding, coordinates)
        {
          organization_embedding: org_embedding,
          cosine_distance: org_embedding.neighbor_distance,
          distance_miles: coordinates ? distance_miles(org_embedding, coordinates) : nil
        }
      end

      # nil means "distance does not apply", which Scorer#distance_score reads
      # as a neutral full mark rather than a penalty.
      #
      # Nationwide organizations get nil deliberately. They are included in a
      # local search precisely because their reach isn't geographic, so
      # measuring from their head office would score a national helpline 0 on
      # the distance term for being headquartered in another state -- punishing
      # them for the property that made them eligible.
      #
      # The trade-off: a nationwide org ties with the nearest local org on this
      # term. That is only 10% of the total, so it still has to win on
      # embedding similarity and rule score, but it does mean nationwide orgs
      # are never distance-disadvantaged. Revisit if they crowd local results.
      def distance_miles(org_embedding, coordinates)
        organization = org_embedding.organization
        return nil if Eligibility::NATIONWIDE_SCOPES.include?(organization.scope_of_work)

        user_point = Geo.point(coordinates[:longitude], coordinates[:latitude])

        # Nearest location, not the main one. An organization with a branch two
        # miles away and a head office forty miles away is two miles away.
        # This also matches how the eligibility filters read locations ("any
        # location offers services"), which measuring from main_location alone
        # contradicted.
        #
        # PO boxes are excluded: they geocode to a post office, which is
        # roughly right for the town and meaningless for a five-mile radius.
        # An organization whose only address is a PO box yields nil, the same
        # neutral "distance doesn't apply" other callers already understand.
        distances = organization.locations.filter_map do |loc|
          next if loc.po_box?
          next if loc.latitude.nil? || loc.longitude.nil?

          user_point.distance(Geo.point(loc.longitude, loc.latitude)) / MILES_TO_METERS
        end

        distances.min
      end

      def expansion_radii(initial_radius)
        # Only consider radii >= the initial radius. Expanding *inward* to a
        # smaller radius after the user's chosen distance failed would
        # contradict the "broaden the search" intent.
        ([initial_radius] + EXPANSION_RADII.select { |r| r >= initial_radius }).uniq.sort
      end

      def matching_rules
        SmartMatch::MATCHING_RULES
      end

      def min_results
        matching_rules.dig("scoring", "min_results") || MIN_RESULTS
      end
    end
  end
end
