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
                        organization: %i[name second_name scope_of_work website ein_number irs_ntee_code
                                         mission_statement_en vision_statement_en tagline_en
                                         mission_statement_es vision_statement_es tagline_es],
                        social_media: %i[facebook instagram twitter linkedin youtube blog]
                      },
                      using: {
                        tsearch: { prefix: true, any_word: true },
                        dmetaphone: {},
                        trigram: {}
                      }
    end
  end
end
