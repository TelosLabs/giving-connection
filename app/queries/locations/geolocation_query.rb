# frozen_string_literal: true

module Locations
  class GeolocationQuery
    DEFAULT_LOCATION = {
      latitude: 36.16404968727089,
      longitude: -86.78125827725053
    }.freeze

    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations
        # Agregar busqueda para landing page
        scope = by_address(scope, params[:address])
        scope = geo_near(scope, starting_coordinates(params[:lat], params[:lon]), params[:distance])
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

    end
  end
end