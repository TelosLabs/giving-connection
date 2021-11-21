# frozen_string_literal: true

class Locations::FilterQuery

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
      # scope = by_service(scope, params[:services])
      # scope = by_beneficiary_groups_served(scope, params[:beneficiary_groups])
      # scope = open_now
      # scope = open_weekends
    end

    def geo_near(scope, coords, distance)
      return if distance.blank? || distance.zero?

      scope.where(
        'ST_DWithin(lonlat, :point, :distance)',
        { point: coords, distance: distance * 1000 } # wants meters not kms
      )
    end

    def by_address(scope, address_params)
      return if address_params.values.all?(&:blank?)

      scope.where(
        'address ILIKE any ( array[?] )',
        parameterize_address_filters(address_params)
      )
    end

    def by_service(scope, services)
      return if services.empty?

      query = <<-SQL
        SELECT * FROM locations
        JOIN location_services ON locations.id = location_services.location_id
        JOIN services ON location_services.service_id = services.id
        WHERE services.name IN '#{services}'
      SQL
      scope.find_by_sql(query)
    end

    def by_beneficiary_groups_served(scope, beneficiary_groups_filters)
      return if beneficiary_groups_filters.empty?

      query = <<-SQL
        SELECT * FROM locations
        JOIN organizations ON organizations.id = locations.organization_id
        JOIN organization_beneficiaries ON organization_beneficiaries.organization_id = organizations.id
        JOIN beneficiary_subcategories ON beneficiary_subcategories.id = organization_beneficiaries.beneficiary_subcategory_id
        WHERE beneficiary_subcategories.name IN '#{beneficiary_groups_filters}'
      SQL
      scope.find_by_sql(query)
    end

    def default_coordinates
      Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude]))
    end

    def parameterize_address_filters(address_params)
      address_params.values.reject!(&:blank?).compact.map { |v| "%#{v}%" }
    end

    # def by_open_now
    #   @locations.joins(:office_hours).where(office_hours: {closed: @closed })
    # end
  end
end
