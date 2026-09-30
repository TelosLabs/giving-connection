# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    # organizations.in_kind_donation_items stores item keys ("towels_washcloths"),
    # not the human-readable labels from Organizations::Constants::IN_KIND_DONATION_ITEMS.
    # pg_search's associated_against needs a real SQL expression (it builds a join
    # subselect), so a Ruby-side label lookup isn't an option here -- instead this
    # unnests the jsonb array and swaps underscores for spaces so "towels" still
    # matches the "towels_washcloths" key via the english tsearch dictionary.
    IN_KIND_DONATION_ITEMS_SEARCH_SQL = Arel.sql(
      "(SELECT string_agg(replace(item, '_', ' '), ' ') " \
      "FROM jsonb_array_elements_text(organizations.in_kind_donation_items) AS item)"
    ).freeze

    included do
      pg_search_scope :search_by_keyword,
        against: {
          name: "A",
          address: "D"
        },
        associated_against: {
          causes: {name: "B"},
          services: {name: "C"},
          tags: {name: "D"},
          organization: {:name => "A", :second_name => nil, :scope_of_work => nil, :website => nil, :ein_number => nil, :irs_ntee_code => nil,
                         :mission_statement_en => nil, :vision_statement_en => nil, :tagline_en => nil,
                         :mission_statement_es => nil, :vision_statement_es => nil, :tagline_es => nil,
                         IN_KIND_DONATION_ITEMS_SEARCH_SQL => "C"},
          social_media: %i[facebook instagram twitter linkedin youtube blog]
        },
        using: {
          tsearch: {dictionary: "english"}
        }
    end
  end
end
