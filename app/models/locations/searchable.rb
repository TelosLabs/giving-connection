# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    included do
      pg_search_scope :search_by_keyword,
                      against: :address,
                      associated_against: {
                        tags: [ :name ],
                        services: [ :name ],
                        organization: [ :name, :scope_of_work, :website, :ein_number, :irs_ntee_code, 
                                        :mission_statement_en, :vision_statement_en, :tagline_en,
                                        :mission_statement_es, :vision_statement_es, :tagline_es ],
                        social_media: [ :facebook, :instagram, :twitter, :linkedin, :youtube, :blog ]
                      },
                      using: {
                        tsearch: { prefix: true, any_word: true }
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

