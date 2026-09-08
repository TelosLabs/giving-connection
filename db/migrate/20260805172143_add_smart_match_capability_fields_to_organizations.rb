# frozen_string_literal: true

# Organization-level capability fields for Smart Match scoring
# (docs/smart-match-scoring/06-phase-5-fields.md).
#
# Every column is NULLABLE WITH NO DEFAULT, and that is load-bearing rather
# than incidental. There is no data to backfill these from -- values arrive
# only as organizations edit their own profiles -- so most rows will stay NULL
# for a long time.
#
# NULL means "nobody has told us". SmartMatch::RuleScorer skips a rule whose
# field is NULL, excluding it from both the earned score and the achievable
# maximum, so an unanswered organization is not penalised and the user's
# normalized score is unaffected.
#
# Defaulting to false would instead record a definite "no" for every
# organization that has never seen the form, which is both wrong and
# unrecoverable -- exactly the trap volunteer_availability fell into with its
# `default: false, null: false`.
#
# The enum/array fields from the same phase (volunteer_format,
# volunteer_frequency, languages, leadership_attributes) are deliberately NOT
# here: their vocabularies are still open questions.
class AddSmartMatchCapabilityFieldsToOrganizations < ActiveRecord::Migration[7.2]
  def change
    change_table :organizations, bulk: true do |t|
      # Find Help — Section 4 preferences
      t.boolean :free_or_sliding_scale
      t.boolean :no_id_required
      t.boolean :lgbtqia_affirming

      # Donor — donation styles
      t.boolean :specific_project_giving
      t.boolean :accepts_in_kind
      t.boolean :recurring_giving

      # Volunteer — ways to help
      t.boolean :fundraising_events
      t.boolean :partnership_opportunities
    end
  end
end
