# frozen_string_literal: true

module Locations
  class FilterQuery

    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations
        scope = by_address(scope, params[:address])
        scope = by_cause(scope, params[:causes])
        scope = by_service(scope, params[:services])
        scope = by_beneficiary_groups_served(scope, params[:beneficiary_groups])
        scope = opened_now(scope, params[:open_now])
        scope = opened_on_weekends(scope, params[:open_weekends])
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

      def by_cause(scope, causes)
        return scope if causes.blank? || scope.empty?

        Location.joins(
          organization: { organization_causes: :cause }
        ).where(
          "locations.id IN (?)", scope.ids
        ).where(
          "causes.name IN (?)", causes
        ).distinct
      end

      def by_service(scope, services)
        return scope if services.blank? || scope.empty?
        complex_query = []
        services.each do |cause, services_list|
          services_list.each do |ser|
            cause = cause&.gsub("'","''") 
            ser = ser&.gsub("'","''") 
            complex_query << "('#{cause}', '#{ser}')"
          end
        end  

        Location.joins(
          location_services: { service: :cause }
        ).where(
          "locations.id IN (?)", scope.ids
        ).where(
          "(causes.name, services.name) IN (#{complex_query.join(",")})"
        ).distinct
      end

      def by_beneficiary_groups_served(scope, beneficiary_groups_filters)
        return scope if beneficiary_groups_filters.blank? || scope.empty?

        complex_query = []
        beneficiary_groups_filters.each do |group, subcategory|
          subcategory.each do |sub|
            group = group&.gsub("'","''")
            complex_query << "('#{group}', '#{sub}')"
          end
        end

        Location.joins(
          organization: { organization_beneficiaries: { beneficiary_subcategory: :beneficiary_group } }
        ).where(
          "locations.id IN (?)", scope.ids
        ).where(
          "(beneficiary_groups.name, beneficiary_subcategories.name) IN (#{complex_query.join(",")})"
        ).distinct
      end

      def parameterize_address_filters(address_params)
        address_params.values.reject!(&:blank?).compact.map { |v| "%#{v}%" }
      end

      def opened_now(scope, open_now)
        return scope if open_now.nil?

        scope.joins(:office_hours).where(office_hours: {
          day: Time.now.wday,
          closed: false,
        }).where(
          '? BETWEEN open_time AND close_time', Time.now
        )
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
