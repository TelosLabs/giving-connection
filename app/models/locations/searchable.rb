# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    included do
      pg_search_scope :search_by_keyword,
                      against: {
                        name: 'A',
                        address: 'D'
                      },
                      associated_against: {
                        causes: { name: 'B' },
                        services: { name: 'C' },
                        tags: { name: 'D' },
                        organization: { name: 'A', second_name: nil, scope_of_work: nil, website: nil, ein_number: nil, irs_ntee_code: nil,
                                        mission_statement_en: nil, vision_statement_en: nil, tagline_en: nil,
                                        mission_statement_es: nil, vision_statement_es: nil, tagline_es: nil },
                        social_media: %i[facebook instagram twitter linkedin youtube blog]
                      },
                      using: {
                        tsearch: { dictionary: 'english' }
                      }
    end
  end
end
