# frozen_string_literal: true

module Organizations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    included do
      DEFAULT_LOCATION_COORDS = {
        latitude: 36.16404968727089,
        longitude: -86.78125827725053
      }.freeze

      pg_search_scope :search_by_keyword,
                      against: :name,
                      using: {
                        tsearch: { prefix: true }
                      }
    end

    class_methods do
      def geo_near(coords, distance)
        where(
          'ST_DWithin(lonlat, :point, :distance)',
          { point: coords, distance: distance * 1000 } # wants meters not kms
        )
      end

      def geolocation_search(kilometers: 10)
        joins(:locations).geo_near(
          Geo.to_wkt(
            Geo.point(
              DEFAULT_LOCATION_COORDS[:longitude],
              DEFAULT_LOCATION_COORDS[:latitude])
            ),
          kilometers.to_i
        )
      end
    end


    def open_now?
      # TODO: Database directly search
      now = Time.now
      today_office_hours = office_hours.where(
        day: Date::DAYNAMES[now.wday]
      )

      today_office_hours.open?(now)
    end

    def open_on_weekends
      # TODO: Database directly search
      weekend_office_hours = office_hours.where(day: ['Saturday', 'Sunday'])

      weekend_office_hours.none? do |woh|
        woh.closed?
      end
    end
  end
end
