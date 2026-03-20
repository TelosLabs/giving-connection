# frozen_string_literal: true

module SmartMatch
  class SimilarityQuery
    EXPANSION_RADII = [5, 10, 25, 50].freeze
    MIN_RESULTS = 3
    MILES_TO_METERS = 1609.344

    class << self
      def call(embedding:, state:, coordinates:, radius_miles: 5)
        all_scope = global_scope
        base_scope = filtered_scope(state)

        if base_scope.none?
          return global_results(all_scope, embedding)
        end

        radii = expansion_radii(radius_miles)

        radii.each do |radius|
          candidates = distance_filtered(base_scope, coordinates, radius)
          next if candidates.none?

          results = ranked_results(candidates, embedding, coordinates)
          return results if results.size >= MIN_RESULTS
        end

        state_wide_results(base_scope, embedding)
      end

      private

      def global_scope
        OrganizationEmbedding
          .joins(organization: :locations)
          .where(locations: {main: true})
          .merge(Location.joins(:organization).where(organizations: {active: true}))
          .distinct
      end

      def global_results(scope, embedding)
        scope
          .nearest_neighbors(:embedding, embedding, distance: "cosine")
          .limit(matching_rules["scoring"]["max_results"])
          .map { |oe| build_result(oe, nil) }
      end

      def filtered_scope(state)
        OrganizationEmbedding
          .joins(organization: :locations)
          .where(locations: {main: true})
          .merge(Location.joins(:organization).where(organizations: {active: true}))
          .merge(location_in_state(state))
          .distinct
      end

      def location_in_state(state)
        Location.where(
          "address ILIKE ?", "%#{sanitize_like(state)}%"
        )
      end

      def distance_filtered(scope, coordinates, radius_miles)
        point = Geo.to_wkt(Geo.point(coordinates[:longitude], coordinates[:latitude]))
        scope.where(
          "ST_DWithin(locations.lonlat, :point, :distance)",
          point: point, distance: radius_miles * MILES_TO_METERS
        )
      end

      def ranked_results(scope, embedding, coordinates)
        scope
          .nearest_neighbors(:embedding, embedding, distance: "cosine")
          .limit(matching_rules["scoring"]["max_results"])
          .map { |oe| build_result(oe, coordinates) }
      end

      def state_wide_results(scope, embedding)
        scope
          .nearest_neighbors(:embedding, embedding, distance: "cosine")
          .limit(matching_rules["scoring"]["max_results"])
          .map { |oe| build_result(oe, nil) }
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

      def sanitize_like(value)
        value.to_s.gsub(/[%_\\]/) { |m| "\\#{m}" }
      end

      def matching_rules
        @matching_rules ||= YAML.load_file(Rails.root.join("config", "matching_rules.yml"))
      end
    end
  end
end
