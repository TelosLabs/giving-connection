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

    # Lets a keyword search find a cause by a related term even when that term
    # never appears verbatim on the organization (e.g. "pregnancy" ->
    # "Health", "religion" -> "Faith-Based" via the english dictionary
    # stemming "religion"/"religious" to the same root). Reuses Smart Match's
    # cause_mappings (config/matching_rules.yml) as the single source of
    # truth for cause synonyms, so updating that file improves both the quiz
    # and this search. Same constraint as IN_KIND_DONATION_ITEMS_SEARCH_SQL
    # above: associated_against needs a real SQL expression, not a Ruby-side
    # lookup, so the mapping is baked into a SQL CASE at load time.
    #
    # Escapes with a plain gsub rather than ActiveRecord::Base.connection.quote:
    # this constant evaluates when Location eager-loads, and production's
    # `rails assets:precompile` (Dockerfile) boots Rails with eager_load=true
    # but no live DB connection, so touching .connection here would break the
    # image build. The data is our own YAML, not user input.
    def self.sql_quote(value)
      "'#{value.gsub("'", "''")}'"
    end

    CAUSE_SYNONYMS_SEARCH_SQL = Arel.sql(
      "(CASE causes.name " +
        SmartMatch::MATCHING_RULES.fetch("cause_mappings", {}).filter_map { |cause_name, data|
          synonyms = Array(data["synonyms"]).join(" ")
          next if synonyms.blank?

          "WHEN #{sql_quote(cause_name)} THEN #{sql_quote(synonyms)} "
        }.join +
        "ELSE '' END)"
    ).freeze

    included do
      pg_search_scope :search_by_keyword,
        against: {
          name: "A",
          address: "D"
        },
        associated_against: {
          causes: {name: "B", CAUSE_SYNONYMS_SEARCH_SQL => "C"},
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
