# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    included do
      pg_search_scope :search_by_keyword,
                      against: :address,
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
    end
  end
end
