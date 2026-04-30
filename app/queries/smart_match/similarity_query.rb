# frozen_string_literal: true

module SmartMatch
  class SimilarityQuery
    EXPANSION_RADII = [5, 10, 25, 50].freeze
    MIN_RESULTS = 3
    MILES_TO_METERS = 1609.344

    class << self
      def call(embedding:, state:, coordinates:, radius_miles: 5)
        state_scope = filtered_scope(state)

        return results_from(base_scope, embedding) if state_scope.none?

        expansion_radii(radius_miles).each do |radius|
          candidates = distance_filtered(state_scope, coordinates, radius)
          next if candidates.none?

          results = results_from(candidates, embedding, coordinates)
          return results if results.size >= MIN_RESULTS
        end

        results_from(state_scope, embedding)
      end

      private

      def base_scope
        OrganizationEmbedding
          .joins(organization: :locations)
          .includes(organization: [:causes, :beneficiary_subcategories, {locations: :services}])
          .where(locations: {main: true})
          .merge(Location.joins(:organization).where(organizations: {active: true}))
          .distinct
      end

      def filtered_scope(state)
        base_scope.merge(location_in_state(state))
      end

      def location_in_state(state)
        Location.where("address ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(state)}%")
      end

      def distance_filtered(scope, coordinates, radius_miles)
        point = Geo.to_wkt(Geo.point(coordinates[:longitude], coordinates[:latitude]))
        scope.where(
          "ST_DWithin(locations.lonlat, :point, :distance)",
          point: point, distance: radius_miles * MILES_TO_METERS
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

      def distance_miles(org_embedding, coordinates)
        loc = org_embedding.organization.main_location
        return nil unless loc

        user_point = Geo.point(coordinates[:longitude], coordinates[:latitude])
        org_point = Geo.point(loc.longitude, loc.latitude)
        user_point.distance(org_point) / MILES_TO_METERS
      end

      def expansion_radii(initial_radius)
        ([initial_radius] + EXPANSION_RADII).uniq.sort
      end

      def matching_rules
        SmartMatch::Config.matching_rules
      end
    end
  end
end
