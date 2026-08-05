# frozen_string_literal: true

# Records which relaxable eligibility filters had to be dropped to produce a
# result set, so the results page can tell the user their search was broadened
# instead of silently showing organizations that don't meet what they asked
# for. Empty array = every filter held.
class AddSearchRelaxationsToQuizSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :quiz_submissions, :search_relaxations, :jsonb, default: [], null: false
  end
end
