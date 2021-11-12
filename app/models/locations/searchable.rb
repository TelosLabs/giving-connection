# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    included do
      pg_search_scope :search_by_keyword,
                      against: :address,
                      associated_against: {
                        tags: [:name],
                        services: [:name],
                        organization: %i[name scope_of_work website ein_number irs_ntee_code
                                         mission_statement_en vision_statement_en tagline_en
                                         mission_statement_es vision_statement_es tagline_es],
                        social_media: %i[facebook instagram twitter linkedin youtube blog]
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

# {"authenticity_token"=>"oC6MgxESKc3yo7iI8daKz-HOEsFXkp9C_
#   pwoo1kgD6_g1htkqf1Ge-sd2pDb pQP1ek7YVR23LkPFe5L0vuKnsg",
#   "distance"=>"10mi", "city"=>"Nashville", "state"=>"TN",
#   "beneficiary_groups"=>"blacks", "cause_and_services"=>"homecare",
#   "open_now"=>"true", "open_weekends"=>"true", "commit"=>"Search",
#   "controller"=>"searches", "action"=>"filter_search"}
