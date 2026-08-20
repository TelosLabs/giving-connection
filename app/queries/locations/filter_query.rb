# frozen_string_literal: true

module Locations
  class FilterQuery
    attr_reader :locations

    # An organization matches a "Give" pill when it offers that way of giving.
    # In-kind matches on either the wishlist link or the selected item list,
    # mirroring when locations/show renders the In-Kind Donation Needs section.
    GIVE_CONDITIONS = {
      Search::GIVE_DONATION =>
        "organizations.donation_link IS NOT NULL AND organizations.donation_link != ''",
      Search::GIVE_VOLUNTEER =>
        "organizations.volunteer_availability = true AND organizations.volunteer_link IS NOT NULL AND organizations.volunteer_link != ''",
      Search::GIVE_IN_KIND =>
        "(organizations.in_kind_donation_link IS NOT NULL AND organizations.in_kind_donation_link != '') OR jsonb_array_length(organizations.in_kind_donation_items) > 0"
    }.freeze

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations
        # scope = by_address(scope, params[:address])
        scope = by_cause(scope, params[:causes])
        scope = by_service(scope, params[:services])
        scope = by_beneficiary_groups_served(scope, params[:beneficiary_groups])
        scope = by_scope_of_work(scope, params[:scope_of_work])
        scope = by_give(scope, params[:give])
        scope = opened_now(scope, params[:open_now])
        # NOTE: this is the return value — every filter must stay in the chain.
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

      def parameterize_address_filters(address_params)
        address_params.values.reject!(&:blank?).compact.map { |v| "%#{v}%" }
      end

      # Builds a bound `(col_a, col_b) IN ((?, ?), ...)` predicate. Values are
      # passed as binds rather than interpolated so names containing quotes
      # cannot break out of the statement.
      def tuple_in(column_a, column_b, pairs)
        placeholders = Array.new(pairs.size, "(?, ?)").join(", ")
        ["(#{column_a}, #{column_b}) IN (#{placeholders})", *pairs.flatten]
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

      def by_give(scope, give_values)
        return scope if give_values.blank? || scope.empty?

        conditions = give_conditions_for(give_values)

        return scope if conditions.empty?

        Location.joins(:organization)
          .where("locations.id IN (?)", scope.ids)
          .where(conditions.map { |c| "(#{c})" }.join(" OR "))
      end

      # How many "Give" pills a location matches, for ordering search results
      # by relevance. Callers apply this directly as an ORDER BY expression
      # rather than round-tripping the order through a per-id sort.
      def give_rank(give_values)
        conditions = give_conditions_for(give_values)
        return Arel.sql("0") if conditions.empty?

        Arel.sql("(#{conditions.map { |c| "(#{c})::int" }.join(" + ")}) DESC")
      end

      private

      def give_conditions_for(give_values)
        GIVE_CONDITIONS.filter_map { |value, condition| condition if Array(give_values).include?(value) }
      end
    end
  end
end
