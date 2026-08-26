# frozen_string_literal: true

require "rails_helper"

# Characterization ("golden master") spec for Smart Match ranking.
#
# This does NOT assert that the ranking is *good* -- it asserts that it has not
# changed by accident. Scoring is a pile of weights whose combined effect is
# hard to hold in your head; a one-line weight change can silently reshuffle
# every result. This spec makes that reshuffle show up as a reviewable diff.
#
# Written before the scoring refinement (docs/smart-match-scoring/) so ranking
# changes across those phases are attributable rather than assumed.
#
# When a change is intentional, regenerate and READ THE DIFF before committing:
#
#     UPDATE_SCORING_BASELINE=1 bundle exec rspec spec/services/smart_match/scoring_baseline_spec.rb
#
# A regenerated baseline with an unexplained diff is worse than no baseline --
# it launders a regression into a committed expectation.
RSpec.describe "Smart Match scoring baseline" do
  let(:baseline_path) { Rails.root.join("spec/fixtures/smart_match/scoring_baseline.json") }

  # Ranked (organization, score, breakdown) per scenario, rounded so trivial
  # float noise doesn't produce diffs.
  #
  # Round-tripped through JSON so the live snapshot is compared like-for-like
  # with the file: the breakdown nests a rule_matches array whose hashes use
  # symbol keys, and those become strings on the way to disk (and to the jsonb
  # column in production). Comparing before the round-trip diffs :answer
  # against "answer" on every single entry.
  def current_snapshot
    organizations = SmartMatchScoringFixtures.create_organizations!
    candidates = SmartMatchScoringFixtures.candidates_for(organizations)

    snapshot = SmartMatchScoringFixtures::SCENARIOS.to_h do |scenario|
      intent = SmartMatchScoringFixtures.user_intent_for(scenario)
      ranked = SmartMatch::Scorer.call(candidates: candidates, user_intent: intent)

      [
        scenario[:key],
        ranked.map do |result|
          {
            "organization" => result[:organization].name,
            "score" => result[:score].to_f.round(4),
            "breakdown" => result[:score_breakdown]
              .transform_values { |v| v.is_a?(Numeric) ? v.to_f.round(4) : v }
          }
        end
      ]
    end

    JSON.parse(JSON.generate(snapshot))
  end

  it "matches the committed baseline" do
    snapshot = current_snapshot

    if ENV["UPDATE_SCORING_BASELINE"] || !baseline_path.exist?
      FileUtils.mkdir_p(baseline_path.dirname)
      baseline_path.write(JSON.pretty_generate(snapshot) + "\n")
      skip "Baseline written to #{baseline_path.relative_path_from(Rails.root)} -- re-run without UPDATE_SCORING_BASELINE to assert against it"
    end

    baseline = JSON.parse(baseline_path.read)

    expect(snapshot.keys).to match_array(baseline.keys),
      "scenario set changed; regenerate the baseline with UPDATE_SCORING_BASELINE=1"

    baseline.each do |scenario_key, expected|
      actual = snapshot.fetch(scenario_key)

      expect(actual.pluck("organization")).to eq(expected.pluck("organization")),
        "ranking order changed for scenario '#{scenario_key}'"
      expect(actual).to eq(expected),
        "scores or breakdowns changed for scenario '#{scenario_key}'"
    end
  end

  # Guards the fixture set itself. A baseline built on organizations whose
  # tagging silently stopped matching real presets would be measuring nothing.
  it "tags fixture organizations with real presets" do
    valid_causes = Organizations::Constants::CAUSES_AND_SERVICES.keys
    valid_services = Organizations::Constants::CAUSES_AND_SERVICES.values.flatten
    valid_beneficiaries = Organizations::Constants::BENEFICIARIES.values.flatten
    valid_ntee = Organizations::Constants::NTEE_CODE

    SmartMatchScoringFixtures::ORGANIZATIONS.each do |spec|
      expect(valid_ntee).to include(spec[:ntee]), "#{spec[:name]}: unknown NTEE code"
      expect(Organizations::Constants::SCOPE).to include(spec[:scope]), "#{spec[:name]}: unknown scope"

      spec[:causes].each { |c| expect(valid_causes).to include(c), "#{spec[:name]}: unknown cause #{c.inspect}" }
      spec[:services].each { |s| expect(valid_services).to include(s), "#{spec[:name]}: unknown service #{s.inspect}" }
      spec[:beneficiaries].each { |b| expect(valid_beneficiaries).to include(b), "#{spec[:name]}: unknown beneficiary #{b.inspect}" }
    end
  end
end
