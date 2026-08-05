# frozen_string_literal: true

require "rails_helper"

# Drift guard for config/smart_match_scoring.yml.
#
# The scoring table references preset names as free-text strings. A renamed
# cause, a mistyped service, or a beneficiary that never existed produces a
# rule that silently never fires -- no error, no log line, just an answer that
# quietly stops affecting results. These specs turn that class of mistake into
# a failing build.
#
# They also enforce coverage in both directions, so a new quiz option cannot
# ship without someone deciding what it is worth.
RSpec.describe "Smart Match scoring rules consistency" do
  let(:rules) { SmartMatch::SCORING_RULES }
  let(:questions) { rules.fetch("questions") }

  let(:valid_causes) { Organizations::Constants::CAUSES_AND_SERVICES.keys }
  let(:valid_services) { Organizations::Constants::CAUSES_AND_SERVICES.values.flatten.uniq }
  let(:valid_beneficiaries) { Organizations::Constants::BENEFICIARIES.values.flatten }
  let(:valid_ntee) { Organizations::Constants::NTEE_CODE }

  def each_rule
    questions.each do |key, question|
      question.fetch("answers", {}).each do |answer, entry|
        list = entry.is_a?(Hash) ? Array(entry["rules"]) : Array(entry)
        list.each { |rule| yield(rule, "#{key}.#{answer}") }
      end
    end
  end

  describe "preset names" do
    it "references only real Cause presets" do
      each_rule do |rule, location|
        next unless rule["field"] == "cause" && rule["preset"]

        expect(valid_causes).to include(rule["preset"]),
          "#{location}: #{rule["preset"].inspect} is not a Cause in Organizations::Constants"
      end
    end

    it "references only real Service presets" do
      each_rule do |rule, location|
        next unless rule["field"] == "service" && rule["preset"]

        expect(valid_services).to include(rule["preset"]),
          "#{location}: #{rule["preset"].inspect} is not a Service in Organizations::Constants"
      end
    end

    it "references only real Populations Served presets" do
      each_rule do |rule, location|
        next unless rule["field"] == "population" && rule["preset"]

        expect(valid_beneficiaries).to include(rule["preset"]),
          "#{location}: #{rule["preset"].inspect} is not a beneficiary subcategory in Organizations::Constants"
      end
    end

    it "references only languages in the supported vocabulary" do
      each_rule do |rule, location|
        next unless rule["field"] == "languages" && rule["preset"]

        expect(Organizations::Constants::LANGUAGES).to include(rule["preset"]),
          "#{location}: #{rule["preset"].inspect} is not in Organizations::Constants::LANGUAGES. " \
          "Add it there first -- a language that isn't in the vocabulary can never be stored, " \
          "so the rule would silently never match."
      end
    end

    it "references NTEE codes that exist, or letter groups that match at least one code" do
      each_rule do |rule, location|
        next unless rule["field"] == "ntee" && rule["preset"]

        if rule["match"] == "prefix"
          expect(valid_ntee.any? { |code| code.start_with?(rule["preset"]) }).to be(true),
            "#{location}: no NTEE code starts with #{rule["preset"].inspect}"
        else
          expect(valid_ntee).to include(rule["preset"]),
            "#{location}: #{rule["preset"].inspect} is not an NTEE code in Organizations::Constants"
        end
      end
    end
  end

  describe "rule shape" do
    it "gives every rule a field and a positive weight" do
      each_rule do |rule, location|
        expect(rule["field"]).to be_present, "#{location}: rule has no field"
        expect(rule["weight"]).to be_a(Numeric).and(be_positive),
          "#{location}: rule has no positive weight"
      end
    end

    it "gives every preset-matching rule a preset" do
      preset_free = SmartMatch::RuleScorer::BOOLEAN_FIELDS.keys
      dynamic = %w[answer cause_service non_default_language]

      each_rule do |rule, location|
        next if preset_free.include?(rule["field"]) || dynamic.include?(rule["match"])
        next if rule["requires_field"]

        expect(rule["preset"]).to be_present,
          "#{location}: rule on #{rule["field"]} needs a preset (or a dynamic match:)"
      end
    end

    it "only uses prefix matching on NTEE codes" do
      each_rule do |rule, location|
        next unless rule["match"] == "prefix"

        expect(rule["field"]).to eq("ntee"), "#{location}: prefix matching only applies to NTEE codes"
      end
    end

    it "resolves every non-deferred field to something the scorer can read" do
      known = %w[population cause service ntee languages] + SmartMatch::RuleScorer::BOOLEAN_FIELDS.keys

      each_rule do |rule, location|
        next if rule["requires_field"]

        expect(known).to include(rule["field"]),
          "#{location}: field #{rule["field"].inspect} has no resolver in RuleScorer. " \
          "Add one, or mark the rule requires_field: true until the column exists."
      end
    end

    it "declares each question against real user paths" do
      valid_paths = %w[service_seeker donor volunteer]

      questions.each do |key, question|
        expect(question["paths"]).to be_present, "#{key}: no paths declared"
        expect(question["paths"] - valid_paths).to be_empty, "#{key}: unknown path"
        expect(question["multiplier"]).to be_a(Numeric), "#{key}: no numeric multiplier"
      end
    end
  end

  describe "answer coverage" do
    # Session keys the scoring table reads, resolving the session_key aliases
    # used where two paths share a question.
    let(:scored_keys) do
      questions.map { |key, question| question["session_key"] || key }.uniq
    end

    it "accounts for every quiz answer, either scored or explicitly ignored" do
      ignored = rules.fetch("ignored_answers").keys
      # travel_bucket and language_input drive retrieval and embedding text
      # respectively rather than preset scoring; asserted in the quiz schema
      # consistency spec instead.
      out_of_scope = %w[travel_bucket language_input]

      unaccounted = UserIntent::QUIZ_ANSWERS.keys.map(&:to_s) -
        scored_keys - ignored - out_of_scope

      expect(unaccounted).to be_empty,
        "these quiz answers are neither scored in smart_match_scoring.yml nor " \
        "listed under ignored_answers: #{unaccounted.join(", ")}. Every question " \
        "needs an explicit scoring decision."
    end

    it "does not both score and ignore the same answer" do
      overlap = scored_keys & rules.fetch("ignored_answers").keys
      expect(overlap).to be_empty, "scored and ignored: #{overlap.join(", ")}"
    end

    it "gives a reason for every ignored answer" do
      rules.fetch("ignored_answers").each do |key, reason|
        expect(reason).to be_present, "#{key}: ignored without a reason"
      end
    end

    # The enumerated questions must cover every option their partial renders --
    # a missing answer is indistinguishable from "scores nothing" at runtime,
    # so it is caught here instead.
    it "covers every option rendered by the enumerated questions' partials" do
      expected = {
        "self_description" => %w[student veteran caregiver lgbtqia disability senior
          children_youth formerly_incarcerated economically_disadvantaged
          currently_unhoused mental_health substance_use health_issues
          business_nonprofit business_partner none],
        "prefs" => %w[free_sliding_scale no_id_required multilingual lgbtqia_affirming
          wheelchair_accessible women_bipoc_led none],
        "donor_communities" => %w[seniors veteran_military spanish_speaking bipoc
          disabilities lgbtqia children_family no_preference],
        "volunteer_type" => %w[kids_seniors veterans_military spanish_speaking
          grassroots_bipoc behind_scenes accessible_virtual family_group no_preference],
        "donation_style" => %w[general_donation specific_project goods_items
          recurring_giving just_exploring],
        "volunteer_involvement" => %w[volunteer_time attend_event business_partner just_exploring],
        "volunteer_format" => %w[in_person remote both],
        "volunteer_time" => %w[one_time few_hours ongoing not_sure],
        "age_range" => %w[under_18 19_24 25_34 35_44 45_54 55_64 over_65 prefer_not_to_say],
        "gender_identity" => %w[female male non_binary other prefer_not_to_say],
        "race_ethnicity" => %w[asian black_african_american hispanic_latino
          middle_eastern_north_african native_american native_hawaiian white
          other prefer_not_to_say]
      }

      expected.each do |session_key, options|
        question = questions.values.find { |q| (q["session_key"] || questions.key(q)) == session_key } ||
          questions[session_key]
        expect(question).to be_present, "no scoring entry for question #{session_key}"

        missing = options - question.fetch("answers", {}).keys
        expect(missing).to be_empty,
          "#{session_key}: no scoring decision for #{missing.join(", ")}. Add rules, " \
          "or an empty list to record that the answer scores nothing."
      end
    end
  end
end
