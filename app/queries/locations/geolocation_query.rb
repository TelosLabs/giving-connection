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

        geo_near(scope, starting_coordinates(params[:lat], params[:lon]), params[:distance])
      end

      def geo_near(scope, coords, distance)
        return scope if distance.blank? || distance.zero? || scope.empty?

        scope.where(
          'ST_DWithin(lonlat, :point, :distance)',
          { point: coords, distance: distance * 1000 } # wants meters not kms
        )
      end

      def starting_coordinates(lat, lon)
        if lat.nil? || lon.nil?
          Geo.to_wkt(Geo.point(DEFAULT_LOCATION[:longitude], DEFAULT_LOCATION[:latitude]))
        else
          Geo.to_wkt(Geo.point(lon, lat))
        end
      end

    end
  end
end