# frozen_string_literal: true

# Bulk OrganizationMatch rows for specs about how many results are SHOWN.
#
# Inserted rather than built through the factories: an :organization builds an
# admin user, a location and a cause apiece, and paging specs need dozens of
# matches while reading nothing but each one's score and rank. Distinct
# organizations are still required -- (quiz_submission_id, organization_id) is
# unique.
module SmartMatchMatchRows
  module_function

  # scores: raw match scores in rank order (best first).
  # breakdown: score_breakdown given to every row -- pass a {"criteria" => [...]}
  #   hash when the spec needs the "how we matched you" panel to render.
  # Returns nothing; query the submission's matches as the code under test would.
  def insert(submission:, scores:, breakdown: {})
    now = Time.current

    ids = Organization.insert_all(
      Array.new(scores.size) do |index|
        {name: "Org #{index}", ein_number: "12-000000#{index}",
         irs_ntee_code: "A90: Arts Services", scope_of_work: "International",
         mission_statement_en: "testing", created_at: now, updated_at: now}
      end, returning: %w[id]
    ).rows.flatten

    OrganizationMatch.insert_all(
      scores.each_with_index.map do |score, index|
        {quiz_submission_id: submission.id, organization_id: ids[index],
         score: score, rank: index + 1, score_breakdown: breakdown, created_at: now}
      end
    )
  end
end
