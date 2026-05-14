# frozen_string_literal: true

class CreateOrganizationMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :organization_matches do |t|
      t.references :quiz_submission, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.decimal :score, precision: 5, scale: 4, null: false
      t.jsonb :score_breakdown, default: {}
      t.integer :rank, null: false

      t.datetime :created_at, null: false
    end

    add_index :organization_matches, [:quiz_submission_id, :organization_id],
      unique: true, name: "idx_org_matches_on_submission_and_org"
  end
end
