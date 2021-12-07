# frozen_string_literal: true

module Locations
  class FilterQuery
    DEFAULT_LOCATION = {
      latitude: 36.16404968727089,
      longitude: -86.78125827725053
    }.freeze

    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.all)
        scope = locations
        scope = geo_near(scope, default_coordinates, params[:distance])
        scope = by_address(scope, params[:address])
        scope = by_service(scope, params[:services])
        scope = by_beneficiary_groups_served(scope, params[:beneficiary_groups])
        scope = opened_now(scope, params[:open_now])
        scope = opened_on_weekends(scope, params[:open_weekends])
      end

      def geo_near(scope, coords, distance)
        return scope if distance.blank? || distance.zero? || scope.empty?

        scope.where(
          'ST_DWithin(lonlat, :point, :distance)',
          { point: coords, distance: distance * 1000 } # wants meters not kms
        )
      end

      def by_address(scope, address_params)
        return scope if address_params.values.all?(&:blank?) || scope.empty?

        address_params[:state_name] = CS.states(:us)[address_params[:state].to_sym]

        scope = scope.where(
          'address ILIKE ANY ( array[?] )',
          ["%#{address_params[:state_name]}%", "%#{address_params[:state]}%"]
        )
        address_params[:state] = nil
        address_params[:state_name] = nil

        return scope if address_params.values.all?(&:blank?)

        scope.where(
          'address ILIKE ALL ( array[?] )',
          parameterize_address_filters(address_params)
        )
      end

      def by_service(scope, services)
        return scope if services.blank? || scope.empty?

        services.each do |cause, services|
          query = Location.joins(
            location_services: { service: :cause }
          ).where(
            'service.name' => services,
            'cause.name' => cause
          ).to_sql
          as_array = scope.find_by_sql(query)
          scope = Location.where(id: as_array.map(&:id))
        end
        scope
      end

      def by_beneficiary_groups_served(scope, beneficiary_groups_filters)
        return scope if beneficiary_groups_filters.blank? || scope.empty?

        beneficiary_groups_filters.each do |group, subcategory|
          query = Location.joins(
            organization: { organization_beneficiaries: { beneficiary_subcategory: :beneficiary_group } }
          ).where(
            'beneficiary_subcategories.name' => subcategory,
            'beneficiary_group.name' => group
          ).to_sql
          as_array = scope.find_by_sql(query)
          scope = Location.where(id: as_array.map(&:id))
        end
        scope
      end

      def default_coordinates
        Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude]))
      end

      def parameterize_address_filters(address_params)
        address_params.values.reject!(&:blank?).compact.map { |v| "%#{v}%" }
      end

      def opened_now(scope, open_now)
        return scope if open_now.nil?

        scope.joins(:office_hours).where(office_hours: {
                                           day: Time.now.wday,
                                           closed: false
                                         })
      end

      def opened_on_weekends(scope, open_on_weekends)
        return scope if open_on_weekends.nil?

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
