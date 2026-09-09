# frozen_string_literal: true

module Locations
  class FilterQuery
    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations
        # scope = by_address(scope, params[:address])
        scope = by_cause(scope, params[:causes])
        scope = by_service(scope, params[:services])
        scope = by_beneficiary_groups_served(scope, params[:beneficiary_groups])
        scope = by_scope_of_work(scope, params[:scope_of_work])
        scope = opened_now(scope, params[:open_now])
        opened_on_weekends(scope, params[:open_weekends])
      end

      def geo_near(scope, coords, distance)
        return scope if distance.blank? || distance.zero? || scope.empty?

        scope.where(
          "ST_DWithin(lonlat, :point, :distance)",
          {point: coords, distance: distance * 1000} # wants meters not kms
        )
      end

      def by_address(scope, address_params)
        return scope if address_params.values.all?(&:blank?) || scope.empty?

        address_params[:state_name] = CS.states(:us)[address_params[:state].to_sym]

        scope = scope.where(
          "address ILIKE ANY ( array[?] )",
          ["%#{address_params[:state_name]}%", "%#{address_params[:state]}%"]
        )
        address_params[:state] = nil
        address_params[:state_name] = nil

        return scope if address_params.values.all?(&:blank?)

        scope.where(
          "address ILIKE ALL ( array[?] )",
          parameterize_address_filters(address_params)
        )
      end

      def by_cause(scope, causes)
        return scope if causes.blank? || scope.empty?

        Location.joins(organization: {organization_causes: :cause})
          .where("locations.id IN (?)", scope.ids)
          .where("causes.name IN (?)", causes)
          .group("locations.id")
          .having("count(locations.id) >= ?", causes.size) # multiple filters add up with AND behavior
      end

      def by_service(scope, services)
        return scope if services.blank? || scope.empty?

        pairs = services.flat_map do |cause, services_list|
          services_list.map { |service| [cause, service] }
        end

        Location.joins(location_services: {service: :cause})
          .where("locations.id IN (?)", scope.ids)
          .where(tuple_in("causes.name", "services.name", pairs))
          .group("locations.id")
          .having("count(locations.id) >= ?", pairs.size) # multiple filters add up with AND behavior
      end

      def by_beneficiary_groups_served(scope, beneficiary_groups_filters)
        return scope if beneficiary_groups_filters.blank? || scope.empty?

        pairs = beneficiary_groups_filters.flat_map do |group, subcategories|
          subcategories.map { |subcategory| [group, subcategory] }
        end

        Location.joins(organization: {organization_beneficiaries: {beneficiary_subcategory: :beneficiary_group}})
          .where("locations.id IN (?)", scope.ids)
          .where(tuple_in("beneficiary_groups.name", "beneficiary_subcategories.name", pairs))
          .group("locations.id")
          .having("count(locations.id) >= ?", pairs.size) # multiple filters add up with AND behavior
      end

      def by_scope_of_work(scope, scope_of_work)
        return scope if scope_of_work.blank? || scope.empty?

        Location.joins(:organization)
          .where("locations.id IN (?)", scope.ids)
          .where("organizations.scope_of_work = ?", scope_of_work)
      end

      def starting_coordinates(lat, lon)
        if lat.nil? || lon.nil?
          Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude]))
        else
          Geo.to_wkt(Geo.point(lon, lat))
        end
      end

      # Builds a bound `(col_a, col_b) IN ((?, ?), ...)` predicate. Values are
      # passed as binds rather than interpolated so names containing quotes
      # cannot break out of the statement.
      def tuple_in(column_a, column_b, pairs)
        # A present filter key with an empty list ({"Youth" => []}) would emit
        # `IN ()` and raise PG::SyntaxError. Nothing can match it, so say so.
        return "1=0" if pairs.empty?

        placeholders = Array.new(pairs.size, "(?, ?)").join(", ")
        # Coerce each half to a scalar before binding. Rack param nesting can
        # deliver a filter value as an array, and a bare `flatten` would spread
        # it into extra binds, breaking arity against the placeholders and
        # raising on a request the old interpolation simply failed to match.
        binds = pairs.flat_map { |a, b| [a.to_s, b.to_s] }
        ["(#{column_a}, #{column_b}) IN (#{placeholders})", *binds]
      end

      def parameterize_address_filters(address_params)
        address_params.values.reject!(&:blank?).compact.map { |v| "%#{v}%" }
      end

      def opened_now(scope, open_now)
        return scope if open_now.nil?

        filtered = scope.select(&:open_now?) # use instance method to filter locations
        Location.where(id: filtered.map(&:id)) # convert array to collection
      end

      def opened_on_weekends(scope, open_on_weekends)
        return scope if !open_on_weekends
        query = <<-SQL
        SELECT *
        FROM locations
        WHERE id IN (
          SELECT location_id
          FROM office_hours oh
          WHERE oh."day" IN (
            #{Time::DAYS_INTO_WEEK[:saturday]},
            #{Time::DAYS_INTO_WEEK[:sunday]}
          )
          GROUP BY location_id, closed
          HAVING count(*) = 2 and closed = false
        )
        SQL
        scope_as_array = scope.find_by_sql(query)
        scope.where(id: scope_as_array.map(&:id))
      end
    end
  end
end
