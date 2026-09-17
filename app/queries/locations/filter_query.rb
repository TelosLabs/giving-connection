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
        "(organizations.in_kind_donation_link IS NOT NULL AND organizations.in_kind_donation_link != '') " \
        "OR (jsonb_typeof(organizations.in_kind_donation_items) = 'array' " \
        "AND jsonb_array_length(organizations.in_kind_donation_items) > 0)"
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
        # NOTE: this is the return value: every filter must stay in the chain.
        opened_on_weekends(scope, params[:open_weekends])
      end

      def by_cause(scope, causes)
        return scope if causes.blank?

        Location.joins(organization: {organization_causes: :cause})
          .where(id: scope)
          .where("causes.name IN (?)", causes)
          .group("locations.id")
          .having("count(locations.id) >= ?", causes.size) # multiple filters add up with AND behavior
      end

      def by_service(scope, services)
        return scope if services.blank?

        pairs = services.flat_map do |cause, services_list|
          services_list.map { |service| [cause, service] }
        end

        Location.joins(location_services: {service: :cause})
          .where(id: scope)
          .where(tuple_in("causes.name", "services.name", pairs))
          .group("locations.id")
          .having("count(locations.id) >= ?", pairs.size) # multiple filters add up with AND behavior
      end

      def by_beneficiary_groups_served(scope, beneficiary_groups_filters)
        return scope if beneficiary_groups_filters.blank?

        pairs = beneficiary_groups_filters.flat_map do |group, subcategories|
          subcategories.map { |subcategory| [group, subcategory] }
        end

        Location.joins(organization: {organization_beneficiaries: {beneficiary_subcategory: :beneficiary_group}})
          .where(id: scope)
          .where(tuple_in("beneficiary_groups.name", "beneficiary_subcategories.name", pairs))
          .group("locations.id")
          .having("count(locations.id) >= ?", pairs.size) # multiple filters add up with AND behavior
      end

      def by_scope_of_work(scope, scope_of_work)
        return scope if scope_of_work.blank?

        Location.joins(:organization)
          .where(id: scope)
          .where("organizations.scope_of_work = ?", scope_of_work)
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

      # Loads each matching location's own `office_hours` row for *today* in one
      # query (instead of `Location#open_now?` -> `today_office_hours` firing a
      # `find_by` per location.
      def opened_now(scope, open_now)
        return scope if open_now.nil?

        today = Time.now.wday
        candidates = scope.to_a
        todays_hours_by_location_id = OfficeHour.where(location_id: candidates.map(&:id), day: today)
          .index_by(&:location_id)

        open_ids = candidates.select do |location|
          office_hour = todays_hours_by_location_id[location.id]
          office_hour.location = location if office_hour # avoids OfficeHour#time_zone re-querying its location
          location.always_open? || office_hour&.open_now?
        end.map(&:id)

        Location.where(id: open_ids)
      end

      def opened_on_weekends(scope, open_on_weekends)
        return scope if !open_on_weekends

        weekend_days = [Time::DAYS_INTO_WEEK[:saturday], Time::DAYS_INTO_WEEK[:sunday]]
        open_both_weekend_days = OfficeHour
          .where(day: weekend_days, closed: false)
          .group(:location_id)
          .having("count(*) = ?", weekend_days.size)
          .select(:location_id)

        scope.where(id: open_both_weekend_days)
      end

      def by_give(scope, give_values)
        return scope if give_values.blank?

        conditions = give_conditions_for(give_values)

        return scope if conditions.empty?

        Location.joins(:organization)
          .where(id: scope)
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
