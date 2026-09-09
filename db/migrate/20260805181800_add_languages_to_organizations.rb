# frozen_string_literal: true

# Languages an organization can deliver services in
# (docs/smart-match-scoring/06-phase-5-fields.md).
#
# A string array rather than booleans or a join table: the vocabulary starts at
# English/Spanish but is expected to grow, and an array makes adding a language
# a one-line change to Organizations::Constants::LANGUAGES with no migration.
# A join table would be more normalised but buys nothing here -- there are no
# attributes to hang off the association.
#
# NULL (not `[]`) means "nobody has told us", and SmartMatch::RuleScorer skips
# unknown fields on both sides of its ratio. An empty array is treated the same
# way, because "serves no languages" is not a meaningful answer -- it only ever
# means the form was submitted without a selection.
class AddLanguagesToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :languages, :string, array: true

    # The scoring rules ask "does this org offer <language>?", which is a
    # containment query. GIN is the index type that serves those.
    add_index :organizations, :languages, using: :gin
  end
end
