# frozen_string_literal: true

# The last three Smart Match fields
# (docs/smart-match-scoring/06-phase-5-fields.md). These were held back from
# the earlier migrations because, unlike the booleans, each needed a
# vocabulary decision -- a boolean got wrong costs a migration, a vocabulary
# got wrong costs a migration *plus* re-collecting from every organization
# that already answered. Values come from the client's CSV.
#
# Nullable with no default, like the rest: NULL means "nobody has told us" and
# SmartMatch::RuleScorer skips those rules on both sides of its ratio.
#
# Shapes differ by what the answer actually is:
#   volunteer_format      single string -- "Hybrid" already means "both", so
#                         the three options are mutually exclusive
#   volunteer_frequency   array -- an organization can offer one-time events
#                         AND ongoing roles
#   leadership_attributes array -- an organization can be both women-led and
#                         BIPOC-led
class AddVolunteerAndLeadershipFieldsToOrganizations < ActiveRecord::Migration[7.2]
  def change
    change_table :organizations, bulk: true do |t|
      t.string :volunteer_format
      t.string :volunteer_frequency, array: true
      t.string :leadership_attributes, array: true
    end

    # Containment queries ("does this org offer ongoing roles?") need GIN.
    add_index :organizations, :volunteer_frequency, using: :gin
    add_index :organizations, :leadership_attributes, using: :gin
  end
end
