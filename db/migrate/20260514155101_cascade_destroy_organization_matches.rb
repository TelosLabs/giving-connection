# frozen_string_literal: true

class CascadeDestroyOrganizationMatches < ActiveRecord::Migration[7.1]
  # organization_matches FKs were created with Rails default (RESTRICT/NO ACTION)
  # in migration 20260305000004. That prevents deleting an Organization or
  # QuizSubmission once any match exists -- not the intended UX for either side.
  # Switch both to ON DELETE CASCADE so admin org deletes and submission cleanup
  # work as expected.
  def up
    remove_foreign_key :organization_matches, :organizations
    remove_foreign_key :organization_matches, :quiz_submissions

    add_foreign_key :organization_matches, :organizations, on_delete: :cascade
    add_foreign_key :organization_matches, :quiz_submissions, on_delete: :cascade
  end

  def down
    remove_foreign_key :organization_matches, :organizations
    remove_foreign_key :organization_matches, :quiz_submissions

    add_foreign_key :organization_matches, :organizations
    add_foreign_key :organization_matches, :quiz_submissions
  end
end
