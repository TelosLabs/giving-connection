# frozen_string_literal: true

module Locations
  class GeolocationQuery
    DEFAULT_LOCATION = {
      latitude: 36.16404968727089,
      longitude: -86.78125827725053
    }.freeze
    DEFAULT_DISTANCE = 20
    DEFAULT_CITY = "Nashville"

    attr_reader :locations

    class << self
      def call(params = {}, locations = Location.active)
        scope = locations

        if params[:lat] && params[:lon]
          scope = geo_near(scope, params[:lat], params[:lon], params[:distance])
        else
          scope = by_city(scope, params[:city])
        end
        scope = by_zipcode(scope, params[:zipcode])
      end

      def by_city(scope, city)
        return scope if scope.empty?

        city = DEFAULT_CITY if city.nil?

        scope.where(
          'address ILIKE ?',
          "%#{city}%"
        )
      end

      def geo_near(scope, lat, lon, distance)
        return scope if scope.empty?

        distance = DEFAULT_DISTANCE if distance.blank? || distance.zero?
        coords = Geo.to_wkt(Geo.point(lon, lat))

        scope.where(
          'ST_DWithin(lonlat, :point, :distance)',
          { point: coords, distance: distance * 1000 } # wants meters not kms
        )
      end

      def by_zipcode(scope, zipcode)
        return scope if scope.empty? || zipcode.blank?

        scope.where(
          'address ILIKE ?',
          "%#{zipcode}%"
        )
      end
    end
  end
end