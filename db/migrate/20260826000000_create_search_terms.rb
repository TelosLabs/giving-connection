# frozen_string_literal: true

# First-party record of what visitors search for.
#
# Deliberately holds no user_id, IP, session id, or any other identifier: these
# rows are meant to be aggregated ("what are the top terms", "which terms return
# nothing"), never to reconstruct one person's search history. On a social
# services directory the keyword itself is sensitive enough — "domestic violence
# shelter", "HIV testing" — that it should not be joinable back to a person.
class CreateSearchTerms < ActiveRecord::Migration[7.2]
  def change
    create_table :search_terms do |t|
      t.string :keyword, null: false
      t.string :normalized_keyword, null: false
      t.integer :results_count, null: false, default: 0
      t.string :origin
      t.string :city
      t.string :state
      t.boolean :filtered, null: false, default: false

      t.timestamps
    end

    add_index :search_terms, :created_at
    add_index :search_terms, [:normalized_keyword, :created_at]
  end
end
