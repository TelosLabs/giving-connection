# frozen_string_literal: true

module Locations
  module Searchable
    extend ActiveSupport::Concern
    include PgSearch::Model

    # organizations.in_kind_donation_items stores item keys ("towels_washcloths"),
    # not the human-readable labels from Organizations::Constants::IN_KIND_DONATION_ITEMS.
    # Written as a real SQL expression (not a Ruby-side label lookup) so it can
    # be embedded directly in TSVECTOR_SQL below -- it unnests the jsonb array
    # and swaps underscores for spaces so "towels" still matches the
    # "towels_washcloths" key via the english tsearch dictionary.
    IN_KIND_DONATION_ITEMS_SEARCH_SQL = Arel.sql(
      "(SELECT string_agg(replace(item, '_', ' '), ' ') " \
      "FROM jsonb_array_elements_text(organizations.in_kind_donation_items) AS item)"
    ).freeze

    # Lets a keyword search find a cause by a related term even when that term
    # never appears verbatim on the organization (e.g. "pregnancy" ->
    # "Health", "religion" -> "Faith-Based"). Reuses Smart Match's
    # cause_mappings (config/matching_rules.yml) as the single source of
    # truth for cause synonyms, so updating that file improves both the quiz
    # and this search. The mapping is baked into a SQL CASE at load time,
    # same constraint as IN_KIND_DONATION_ITEMS_SEARCH_SQL above.
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

    # Field list + weights for locations.search_vector, replicating what the
    # old live pg_search_scope (against:/associated_against:) computed on
    # every request. Kept as one ordered list, rather than duplicated between
    # a query-time scope and a write-time refresh, since there's now only one
    # place this needs to be correct: here, at write time.
    #
    # Each entry is [sql_expression, weight_or_nil]. Expressions referencing
    # has-many associations (causes, services, tags) are correlated
    # subqueries against locations.id/locations.organization_id so they work
    # standalone in TSVECTOR_SQL's FROM; organizations/social_medias fields
    # are plain columns because TSVECTOR_SQL joins those tables once.
    TSVECTOR_FIELDS = [
      ["locations.name", "A"],
      ["locations.address", "D"],
      [
        "(SELECT string_agg(causes.name, ' ') FROM causes " \
        "INNER JOIN organization_causes ON organization_causes.cause_id = causes.id " \
        "WHERE organization_causes.organization_id = locations.organization_id)",
        "B"
      ],
      [
        "(SELECT string_agg(#{CAUSE_SYNONYMS_SEARCH_SQL}, ' ') FROM causes " \
        "INNER JOIN organization_causes ON organization_causes.cause_id = causes.id " \
        "WHERE organization_causes.organization_id = locations.organization_id)",
        "C"
      ],
      [
        "(SELECT string_agg(services.name, ' ') FROM services " \
        "INNER JOIN location_services ON location_services.service_id = services.id " \
        "WHERE location_services.location_id = locations.id)",
        "C"
      ],
      [
        "(SELECT string_agg(tags.name, ' ') FROM tags WHERE tags.organization_id = locations.organization_id)",
        "D"
      ],
      ["organizations.name", "A"],
      ["organizations.second_name", nil],
      ["organizations.scope_of_work", nil],
      ["organizations.website", nil],
      ["organizations.ein_number", nil],
      ["organizations.irs_ntee_code", nil],
      ["organizations.mission_statement_en", nil],
      ["organizations.vision_statement_en", nil],
      ["organizations.tagline_en", nil],
      ["organizations.mission_statement_es", nil],
      ["organizations.vision_statement_es", nil],
      ["organizations.tagline_es", nil],
      [IN_KIND_DONATION_ITEMS_SEARCH_SQL.to_s, "C"],
      ["social_medias.facebook", nil],
      ["social_medias.instagram", nil],
      ["social_medias.twitter", nil],
      ["social_medias.linkedin", nil],
      ["social_medias.youtube", nil],
      ["social_medias.blog", nil]
    ].freeze

    TSVECTOR_SQL = Arel.sql(
      TSVECTOR_FIELDS.map { |expr, weight|
        tsvector = "to_tsvector('english', coalesce((#{expr}), ''))"
        weight ? "setweight(#{tsvector}, '#{weight}')" : tsvector
      }.join(" || ")
    ).freeze

    included do
      pg_search_scope :search_by_keyword,
        against: :name, # unused once tsvector_column is set; pg_search still requires a value here
        using: {
          tsearch: {dictionary: "english", tsvector_column: "search_vector"}
        }
    end

    class_methods do
      # Recomputes and stores search_vector for the given location ids.
      # Call this instead of relying on the (removed) live-computed scope --
      # a location with a stale or NULL search_vector simply won't surface in
      # keyword search until this runs for it, so Locations::RefreshSearchVectorJob
      # wires this to the models that feed TSVECTOR_SQL, with a nightly
      # reconciliation pass (config/clock.rb) as a self-healing backstop.
      def refresh_search_vector!(location_ids)
        ids = Array(location_ids).map(&:to_i)
        return if ids.empty?

        sql = ActiveRecord::Base.sanitize_sql_array([
          <<~SQL.squish,
            UPDATE locations
            SET search_vector = computed.vector
            FROM (
              SELECT locations.id AS location_id, (#{TSVECTOR_SQL}) AS vector
              FROM locations
              LEFT JOIN organizations ON organizations.id = locations.organization_id
              LEFT JOIN social_medias ON social_medias.organization_id = organizations.id
              WHERE locations.id IN (?)
            ) AS computed
            WHERE locations.id = computed.location_id
          SQL
          ids
        ])
        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end
end
