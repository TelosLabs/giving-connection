# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::RuleScorer do
  # Builds an organization with exact preset tagging. Defaults are deliberately
  # empty so each spec states only the tagging it depends on.
  def build_org(causes: [], beneficiaries: [], services: [], ntee: "A90: Arts Services", **attrs)
    org = create(:organization, irs_ntee_code: ntee, **attrs)
    org.causes = causes.map { |n| SmartMatchScoringFixtures.find_or_create_cause(n) }
    org.beneficiary_subcategories = beneficiaries.map { |n| SmartMatchScoringFixtures.find_or_create_beneficiary(n) }
    org.locations.first.services = services.map { |n| SmartMatchScoringFixtures.find_or_create_service(n) }
    org.reload
  end

  def intent(user_type: "service_seeker", **answers)
    UserIntent.from_session(session_answers: answers, user_type: user_type)
  end

  def score_for(org, user_intent)
    described_class.call(organization: org, user_intent: user_intent)
  end

  describe "normalization" do
    it "scores 1.0 when an organization matches everything the answers can reward" do
      org = build_org(
        causes: ["Seniors"],
        beneficiaries: ["Seniors"],
        services: ["Senior Centers"],
        ntee: "P81: Senior Centers"
      )

      result = score_for(org, intent(self_description: ["senior"]))

      expect(result[:score]).to eq(1.0)
    end

    it "scores 0.0 when an organization matches nothing" do
      org = build_org(causes: ["Animals"])

      expect(score_for(org, intent(self_description: ["senior"]))[:score]).to eq(0.0)
    end

    # The failure mode normalization exists to prevent: without it, a user who
    # ticks four boxes accumulates more raw points than one who ticks a single
    # box, so their best match outranks the other's equally-good best match.
    it "does not advantage users who select more answers" do
      senior_org = build_org(
        causes: ["Seniors"], beneficiaries: ["Seniors"],
        services: ["Senior Centers"], ntee: "P81: Senior Centers"
      )

      focused = score_for(senior_org, intent(self_description: ["senior"]))
      broad = score_for(senior_org, intent(self_description: %w[senior veteran student lgbtqia]))

      expect(focused[:score]).to eq(1.0)
      expect(broad[:score]).to be < focused[:score]
      expect(broad[:earned]).to eq(focused[:earned])
      expect(broad[:max]).to be > focused[:max]
    end
  end

  describe "within-group aggregation" do
    # "Children & Youth" lists three populations at weight 5. An org tagged
    # with all three must score the same as one tagged with a single match --
    # otherwise ranking rewards tag volume rather than fit.
    it "takes the highest weight in a field group rather than summing" do
      one_tag = build_org(beneficiaries: ["Children & Youth"])
      three_tags = build_org(
        name: "Broadly Tagged Org", ein_number: "556677",
        beneficiaries: ["Children & Youth", "Individuals Under 21", "Non-Adults"]
      )

      answers = intent(self_description: ["children_youth"])

      expect(score_for(three_tags, answers)[:earned]).to eq(score_for(one_tag, answers)[:earned])
    end

    it "sums across different field groups" do
      population_only = build_org(beneficiaries: ["Seniors"])
      population_and_cause = build_org(
        name: "Fuller Org", ein_number: "556678",
        beneficiaries: ["Seniors"], causes: ["Seniors"]
      )

      answers = intent(self_description: ["senior"])

      expect(score_for(population_and_cause, answers)[:earned])
        .to be > score_for(population_only, answers)[:earned]
    end
  end

  describe "question multipliers" do
    it "applies the question multiplier to earned weight" do
      org = build_org(beneficiaries: ["Seniors"])

      # self_description is High priority (1.5); a population match is weight 5.
      expect(score_for(org, intent(self_description: ["senior"]))[:earned]).to eq(7.5)
    end

    it "honours an answer-level multiplier override" do
      # wheelchair_accessible is Medium (1.0) inside a question whose default
      # is Low (0.5). It is deferred, so assert the config rather than a score.
      prefs = SmartMatch::SCORING_RULES.dig("questions", "prefs")

      expect(prefs["multiplier"]).to eq(0.5)
      expect(prefs.dig("answers", "wheelchair_accessible", "multiplier")).to eq(1.0)
    end
  end

  describe "match modes" do
    it "matches NTEE letter groups by prefix" do
      org = build_org(beneficiaries: ["People with Mental Health Issues"], ntee: "F30: Mental Health Treatment")

      trace = score_for(org, intent(self_description: ["mental_health"]))[:matched]

      expect(trace.map { |m| m[:field] }).to include("ntee")
    end

    it "does not match an NTEE letter group against an unrelated letter" do
      org = build_org(beneficiaries: ["People with Mental Health Issues"], ntee: "A90: Arts Services")

      trace = score_for(org, intent(self_description: ["mental_health"]))[:matched]

      expect(trace.map { |m| m[:field] }).not_to include("ntee")
    end

    it "matches a selected cause against the organization's own causes" do
      org = build_org(causes: ["Mental Health"])

      result = score_for(org, intent(causes: ["Mental Health"]))

      expect(result[:matched].map { |m| m[:field] }).to include("cause")
      expect(result[:earned]).to eq(7.5) # weight 5 x 1.5
    end

    it "matches services belonging to the selected cause" do
      org = build_org(services: ["Mental Health Counseling"])

      result = score_for(org, intent(causes: ["Mental Health"]))

      expect(result[:matched].map { |m| m[:field] }).to include("service")
    end

    it "scores a donation link for donors" do
      with_link = build_org(donation_link: "https://example.org/give")
      without = build_org(name: "No Link Org", ein_number: "556679")

      answers = intent(user_type: "donor", causes: ["Seniors"])

      expect(score_for(with_link, answers)[:earned]).to be > score_for(without, answers)[:earned]
    end
  end

  describe "answers that must not score" do
    it "ignores escape-hatch answers entirely" do
      org = build_org(beneficiaries: ["Seniors"], causes: ["Seniors"])

      result = score_for(org, intent(self_description: ["none"], prefs: ["none"]))

      expect(result[:earned]).to eq(0.0)
      expect(result[:max]).to eq(0.0)
      expect(result[:score]).to eq(0.0)
    end

    # Selecting "no preference" must not quietly depress the score by inflating
    # the achievable maximum.
    it "does not let an escape hatch dilute a real match" do
      org = build_org(beneficiaries: ["Seniors"], causes: ["Seniors"],
        services: ["Senior Centers"], ntee: "P81: Senior Centers")

      with_hatch = score_for(org, intent(self_description: %w[senior none]))
      without = score_for(org, intent(self_description: ["senior"]))

      expect(with_hatch[:score]).to eq(without[:score])
    end

    it "does not score information-only answers" do
      org = build_org(causes: ["Seniors"])

      result = score_for(org, intent(situation: "urgent", support_for: "myself"))

      expect(result[:matched]).to be_empty
    end
  end

  # The mechanism the no-backfill decision rests on
  # (docs/smart-match-scoring/06-phase-5-fields.md). These fields ship empty
  # and fill in slowly, so "nobody has told us" must behave differently from
  # "no".
  describe "capability fields with no data yet" do
    # wheelchair_accessible lives on locations, not organizations -- a branch
    # can be step-free while head office isn't.
    def org_with_accessibility(value)
      org = build_org
      org.locations.first.update_columns(wheelchair_accessible: value)
      org.reload
    end

    it "scores an organization that says yes" do
      result = score_for(org_with_accessibility(true), intent(prefs: ["wheelchair_accessible"]))

      expect(result[:earned]).to eq(4.0) # weight 4 x answer-level multiplier 1.0
      expect(result[:score]).to eq(1.0)
    end

    it "counts an explicit no against the achievable maximum" do
      result = score_for(org_with_accessibility(false), intent(prefs: ["wheelchair_accessible"]))

      expect(result[:earned]).to eq(0.0)
      expect(result[:max]).to eq(4.0)
      expect(result[:score]).to eq(0.0)
    end

    # The important one. An unanswered organization must be indistinguishable
    # from one the question was never asked about -- neither rewarded nor
    # punished -- otherwise every org would be suppressed until backfilled.
    it "ignores an unanswered field entirely, on both sides of the ratio" do
      org = build_org # wheelchair_accessible is NULL

      result = score_for(org, intent(prefs: ["wheelchair_accessible"]))

      expect(result[:earned]).to eq(0.0)
      expect(result[:max]).to eq(0.0)
      expect(result[:matched]).to be_empty
    end

    it "does not let unanswered preferences dilute a scored match" do
      org = build_org(beneficiaries: ["Seniors"], causes: ["Seniors"],
        services: ["Senior Centers"], ntee: "P81: Senior Centers")

      plain = score_for(org, intent(self_description: ["senior"]))
      with_unknowns = score_for(org, intent(
        self_description: ["senior"],
        prefs: %w[wheelchair_accessible free_sliding_scale no_id_required]
      ))

      expect(with_unknowns[:score]).to eq(plain[:score])
      expect(with_unknowns[:max]).to eq(plain[:max])
    end

    describe "languages" do
      it "scores a named language for the volunteer Spanish-speaking answer" do
        spanish = build_org(languages: ["English", "Spanish"])
        english = build_org(name: "English Only", ein_number: "660011", languages: ["English"])

        answers = intent(user_type: "volunteer", volunteer_type: ["spanish_speaking"])

        expect(score_for(spanish, answers)[:earned]).to eq(5.0) # weight 5 x 1.0
        expect(score_for(english, answers)[:earned]).to eq(0.0)
      end

      # The preference is worded "Spanish or another language available", so it
      # asks for any language beyond the assumed default rather than a specific
      # one.
      it "scores any non-default language for the multilingual preference" do
        spanish = build_org(languages: ["Spanish"])
        english = build_org(name: "English Only", ein_number: "660012", languages: ["English"])

        answers = intent(prefs: ["multilingual"])

        expect(score_for(spanish, answers)[:earned]).to eq(1.0) # weight 2 x 0.5
        expect(score_for(english, answers)[:earned]).to eq(0.0)
        expect(score_for(english, answers)[:max]).to eq(1.0), "English-only is a known no, not unknown"
      end

      it "treats an organization with no languages recorded as unknown" do
        org = build_org # languages is NULL

        result = score_for(org, intent(prefs: ["multilingual"]))

        expect(result[:max]).to eq(0.0)
        expect(result[:matched]).to be_empty
      end

      it "treats an empty language list as unknown rather than as a no" do
        org = build_org(languages: [])

        expect(score_for(org, intent(prefs: ["multilingual"]))[:max]).to eq(0.0)
      end
    end

    describe "location-level fields" do
      it "counts the organization as accessible when any location is" do
        org = build_org
        org.locations.first.update_columns(wheelchair_accessible: false)
        create(:location, :with_office_hours, organization: org, main: false,
          offer_services: true, wheelchair_accessible: true)

        result = score_for(org.reload, intent(prefs: ["wheelchair_accessible"]))

        expect(result[:earned]).to eq(4.0)
      end

      it "treats a partly-audited organization as a known no, not unknown" do
        org = build_org
        org.locations.first.update_columns(wheelchair_accessible: false)
        create(:location, :with_office_hours, organization: org, main: false, offer_services: true)

        result = score_for(org.reload, intent(prefs: ["wheelchair_accessible"]))

        expect(result[:earned]).to eq(0.0)
        expect(result[:max]).to eq(4.0), "one audited location makes this a known answer"
      end

      it "treats a wholly unaudited organization as unknown" do
        org = build_org
        create(:location, :with_office_hours, organization: org, main: false, offer_services: true)

        result = score_for(org.reload, intent(prefs: ["wheelchair_accessible"]))

        expect(result[:max]).to eq(0.0)
      end
    end
  end

  describe "fields that do not exist yet" do
    # A deferred rule must affect neither side of the ratio. If it counted
    # toward the maximum, selecting "wheelchair accessible" would permanently
    # cap every result below 1.0 for data the platform has not collected.
    it "excludes deferred rules from both earned and maximum" do
      org = build_org(beneficiaries: ["Seniors"], causes: ["Seniors"],
        services: ["Senior Centers"], ntee: "P81: Senior Centers")

      plain = score_for(org, intent(self_description: ["senior"]))
      with_deferred = score_for(org, intent(
        self_description: ["senior"],
        prefs: %w[wheelchair_accessible free_sliding_scale no_id_required]
      ))

      expect(with_deferred[:max]).to eq(plain[:max])
      expect(with_deferred[:score]).to eq(plain[:score])
    end

    it "still scores the parts of a preference that existing data can satisfy" do
      # lgbtqia_affirming has a deferred flag plus population/service rules
      # that work today.
      org = build_org(beneficiaries: ["LGBTQ+ People"], services: ["LGBTQ+ Advocacy"])

      result = score_for(org, intent(prefs: ["lgbtqia_affirming"]))

      expect(result[:earned]).to be > 0
      expect(result[:matched].map { |m| m[:field] }).to contain_exactly("population", "service")
    end
  end

  # The CSV scores these at +2 x 0.5 on Find Help only, and qualifies gender
  # and race with "when a corresponding preset exists". These specs pin both
  # halves: what maps, and what deliberately does not.
  describe "personal details" do
    it "matches an age answer to age-related populations" do
      senior_org = build_org(beneficiaries: ["Seniors"])
      youth_org = build_org(name: "Youth Org", ein_number: "770011", beneficiaries: ["Children & Youth"])

      answers = intent(age_range: "over_65")

      expect(score_for(senior_org, answers)[:earned]).to eq(1.0) # 2 x 0.5
      expect(score_for(youth_org, answers)[:earned]).to eq(0.0)
    end

    it "matches gender answers that have an exact preset" do
      womens_org = build_org(beneficiaries: ["Women & Girls"])

      expect(score_for(womens_org, intent(gender_identity: "female"))[:earned]).to eq(1.0)
      expect(score_for(womens_org, intent(gender_identity: "male"))[:earned]).to eq(0.0)
    end

    it "matches race answers to their descent preset" do
      org = build_org(beneficiaries: ["People of African Descent"])

      expect(score_for(org, intent(race_ethnicity: "black_african_american"))[:earned]).to eq(1.0)
      expect(score_for(org, intent(race_ethnicity: "asian"))[:earned]).to eq(0.0)
    end

    it "also matches an organization serving all racial minority groups" do
      broad = build_org(beneficiaries: ["People of all Racial Minority Groups"])

      expect(score_for(broad, intent(race_ethnicity: "asian"))[:earned]).to eq(1.0)
    end

    # Only the highest weight in a field group counts, so an organization
    # carrying both the exact descent preset and the umbrella one scores the
    # same as one carrying either.
    it "does not double-count the descent and umbrella presets" do
      both = build_org(beneficiaries: ["People of Asian Descent", "People of all Racial Minority Groups"])
      one = build_org(name: "One Tag", ein_number: "770012", beneficiaries: ["People of Asian Descent"])

      answers = intent(race_ethnicity: "asian")

      expect(score_for(both, answers)[:earned]).to eq(score_for(one, answers)[:earned])
    end

    it "does not pair a white answer with the racial-minority preset" do
      minority_org = build_org(beneficiaries: ["People of all Racial Minority Groups"])

      expect(score_for(minority_org, intent(race_ethnicity: "white"))[:earned]).to eq(0.0)
    end

    # The vocabulary has no honest equivalent for these, and the CSV only asks
    # for a match "when a corresponding preset exists". Scoring nothing is the
    # intended behaviour, not an oversight -- a non-binary person seeking food
    # assistance should not be steered toward LGBTQ+-specific organizations by
    # their gender answer alone.
    it "scores nothing for answers with no corresponding preset" do
      lgbtq_org = build_org(beneficiaries: ["LGBTQ+ People"])

      %w[non_binary other prefer_not_to_say].each do |answer|
        result = score_for(lgbtq_org, intent(gender_identity: answer))
        expect(result[:earned]).to eq(0.0), "gender #{answer} should not score"
        expect(result[:max]).to eq(0.0), "gender #{answer} should not affect the maximum either"
      end

      %w[other prefer_not_to_say].each do |answer|
        expect(score_for(lgbtq_org, intent(race_ethnicity: answer))[:max]).to eq(0.0)
      end
    end

    it "does not score personal details on the donor or volunteer paths" do
      org = build_org(beneficiaries: ["Seniors", "Women & Girls", "People of African Descent"])

      %w[donor volunteer].each do |user_type|
        result = score_for(org, intent(
          user_type: user_type, age_range: "over_65",
          gender_identity: "female", race_ethnicity: "black_african_american"
        ))
        expect(result[:matched]).to be_empty, "#{user_type} should treat personal details as information only"
      end
    end
  end

  describe "path scoping" do
    it "ignores questions belonging to another path" do
      org = build_org(beneficiaries: ["Seniors"])

      # donor_communities is a Donor question; a service_seeker sending it
      # must not be scored on it.
      result = score_for(org, intent(user_type: "service_seeker", donor_communities: ["seniors"]))

      expect(result[:matched]).to be_empty
    end

    it "applies the path-specific weight for the shared cause question" do
      org = build_org(services: ["Senior Centers"])

      seeker = score_for(org, intent(user_type: "service_seeker", causes: ["Seniors"]))
      donor = score_for(org, intent(user_type: "donor", causes: ["Seniors"]))

      # The CSV grades the service tier +4 on Find Help and +3 on Donor.
      expect(seeker[:earned]).to eq(6.0)  # 4 x 1.5
      expect(donor[:earned]).to eq(4.5)   # 3 x 1.5
    end
  end

  describe "the trace" do
    it "itemizes each match with enough detail to explain the score" do
      org = build_org(beneficiaries: ["Seniors"])

      entry = score_for(org, intent(self_description: ["senior"]))[:matched].first

      expect(entry).to include(
        question: "self_description",
        answer: "senior",
        field: "population",
        preset: "Seniors",
        weight: 5,
        multiplier: 1.5,
        contribution: 7.5
      )
    end
  end

  describe "query behaviour" do
    def count_queries
      count = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
        count += 1 unless payload[:name].in?(["SCHEMA", "TRANSACTION"]) || payload[:sql].start_with?("SAVEPOINT", "RELEASE")
      end
      yield
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The scorer runs over every retrieved candidate (up to scoring.max_results).
    # Reading associations with map(&:name) rather than pluck keeps it inside
    # the preload SimilarityQuery#base_scope already performs; a stray query
    # here becomes 20 per submission.
    it "issues no queries per candidate when associations are preloaded" do
      orgs = SmartMatchScoringFixtures.create_organizations!
      answers = intent(self_description: %w[senior veteran], causes: ["Seniors"])

      preloaded = Organization
        .includes(:causes, :beneficiary_subcategories, {locations: :services})
        .where(id: orgs.map(&:id)).to_a

      queries = count_queries { preloaded.each { |org| score_for(org, answers) } }

      expect(queries).to eq(0)
    end
  end
end
