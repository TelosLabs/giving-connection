# frozen_string_literal: true

# Location-level Smart Match fields
# (docs/smart-match-scoring/06-phase-5-fields.md).
#
# These two sit on locations rather than organizations because they genuinely
# vary per site: a branch can be step-free while the head office isn't, and an
# organization can run in-person services at one site and remote services from
# another. Only ~30 production organizations have more than one location, so
# this affects few records -- but moving them later would need a second
# migration plus a data move, so the distinction is made now.
#
# Nullable with no default, for the same reason as the organization-level
# fields: NULL means "nobody has told us" and is skipped by RuleScorer, rather
# than recording a definite "not accessible" for every un-audited location.
#
# remote_services also backs a relaxable eligibility filter, which is what
# finally lets the "Remote services only" travel option mean what it says.
class AddSmartMatchAccessibilityFieldsToLocations < ActiveRecord::Migration[7.2]
  def change
    change_table :locations, bulk: true do |t|
      t.boolean :wheelchair_accessible
      t.boolean :remote_services
    end

    # Partial index: the eligibility filter only ever looks for locations where
    # this is true, and true rows will be a small minority for a long time.
    add_index :locations, :remote_services, where: "remote_services = true"
  end
end
