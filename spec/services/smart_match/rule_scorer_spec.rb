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

  # Services refine a search within a cause; they must not behave like a filter.
  #
  # Scored independently, each selected service added its full weight to the
  # achievable maximum, so ticking six services buried every organization that
  # served the right cause but not those exact services. Collapsing the
  # question into one proportional slot keeps it a refinement.
  describe "services as a refinement, not a blocker" do
    it "does not let extra service selections erode a cause match" do
      org = build_org(causes: ["Mental Health"])

      one = score_for(org, intent(causes: ["Mental Health"], services: ["Mental Health Counseling"]))
      many = score_for(org, intent(
        causes: ["Mental Health"],
        services: ["Mental Health Counseling", "Therapy Services", "Psychiatric Care",
          "Trauma Services", "Suicide Prevention Services", "Crisis Intervention"]
      ))

      # Six services must cost no more of the achievable maximum than one.
      expect(many[:max]).to eq(one[:max])
      expect(many[:score]).to eq(one[:score])
    end

    it "keeps an organization matching the cause ahead of one matching neither" do
      on_cause = build_org(causes: ["Mental Health"])
      unrelated = build_org(name: "Unrelated", ein_number: "990011", causes: ["Animals"])

      answers = intent(
        causes: ["Mental Health"],
        services: ["Therapy Services", "Psychiatric Care", "Trauma Services"]
      )

      expect(score_for(on_cause, answers)[:score]).to be > score_for(unrelated, answers)[:score]
    end

    it "still rewards matching more of the requested services" do
      one_service = build_org(services: ["Therapy Services"])
      two_services = build_org(name: "Two Services", ein_number: "990012",
        services: ["Therapy Services", "Psychiatric Care"])

      answers = intent(services: ["Therapy Services", "Psychiatric Care"])

      expect(score_for(two_services, answers)[:score]).to be > score_for(one_service, answers)[:score]
    end

    it "earns the slot in proportion to how many services matched" do
      half = build_org(services: ["Therapy Services"])

      result = score_for(half, intent(services: ["Therapy Services", "Psychiatric Care"]))

      expect(result[:earned]).to eq(result[:max] / 2)
    end

    it "caps the whole question at one answer's weight" do
      org = build_org(services: ["Therapy Services", "Psychiatric Care"])

      result = score_for(org, intent(services: ["Therapy Services", "Psychiatric Care"]))

      # weight 5 x multiplier 1.5, once -- not once per service.
      expect(result[:max]).to eq(7.5)
    end
  end

  # The causes step offers two cards ("Financial assistance" and "Human &
  # social services") that submit the same canonical cause, so ticking both put
  # the value in the array twice -- scoring it as two criteria and doubling its
  # weight against everything else.
  describe "repeated answers" do
    it "scores a duplicated cause exactly once" do
      org = build_org(causes: ["Human & Social Services"])

      once = score_for(org, intent(causes: ["Human & Social Services"]))
      twice = score_for(org, intent(causes: ["Human & Social Services", "Human & Social Services"]))

      expect(twice[:max]).to eq(once[:max])
      expect(twice[:earned]).to eq(once[:earned])
    end

    it "lists a duplicated answer once in the criteria" do
      org = build_org(causes: ["Human & Social Services"])

      criteria = score_for(org, intent(causes: ["Human & Social Services", "Human & Social Services"]))[:criteria]

      expect(criteria.count { |c| c[:answer] == "Human & Social Services" }).to eq(1)
    end

    it "does not let a duplicate crowd out another answer" do
      org = build_org(causes: ["Seniors"])

      focused = score_for(org, intent(causes: ["Seniors"]))
      with_dupe = score_for(org, intent(causes: ["Seniors", "Human & Social Services", "Human & Social Services"]))

      # One extra distinct cause, not two -- so the denominator grows once.
      expect(with_dupe[:max]).to eq(focused[:max] * 2)
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

    # The quiz asks what the user wants; the organization records what it
    # offers; the two vocabularies deliberately differ. RuleScorer bridges them
    # via ANSWER_VOCABULARY.
    describe "volunteer format" do
      def volunteer(answer)
        intent(user_type: "volunteer", volunteer_format: answer)
      end

      it "accepts a hybrid programme for an in-person request" do
        hybrid = build_org(volunteer_format: "Hybrid")
        in_person = build_org(name: "In Person Only", ein_number: "aa011", volunteer_format: "In person")
        remote = build_org(name: "Remote Only", ein_number: "aa012", volunteer_format: "Remote")

        expect(score_for(hybrid, volunteer("in_person"))[:earned]).to eq(7.5) # 5 x 1.5
        expect(score_for(in_person, volunteer("in_person"))[:earned]).to eq(7.5)
        expect(score_for(remote, volunteer("in_person"))[:earned]).to eq(0.0)
      end

      it "accepts a hybrid programme for a remote request" do
        hybrid = build_org(volunteer_format: "Hybrid")
        in_person = build_org(name: "In Person Only", ein_number: "aa013", volunteer_format: "In person")

        expect(score_for(hybrid, volunteer("remote"))[:earned]).to eq(7.5)
        expect(score_for(in_person, volunteer("remote"))[:earned]).to eq(0.0)
      end

      it "accepts any format when the user is happy with both" do
        %w[In\ person Remote Hybrid].each_with_index do |format, i|
          org = build_org(name: "Fmt #{i}", ein_number: "aa02#{i}", volunteer_format: format)
          expect(score_for(org, volunteer("both"))[:earned]).to eq(7.5), "#{format} should satisfy 'both'"
        end
      end

      it "treats an organization with no recorded format as unknown" do
        org = build_org

        expect(score_for(org, volunteer("in_person"))[:max]).to eq(0.0)
      end
    end

    describe "volunteer frequency" do
      def volunteer(answer)
        intent(user_type: "volunteer", volunteer_time: answer)
      end

      it "matches one-time requests against one-off and event-based programmes" do
        event = build_org(volunteer_frequency: ["Event-based"])
        ongoing = build_org(name: "Ongoing Only", ein_number: "aa031", volunteer_frequency: ["Ongoing"])

        expect(score_for(event, volunteer("one_time"))[:earned]).to eq(3.0) # 3 x 1.0
        expect(score_for(ongoing, volunteer("one_time"))[:earned]).to eq(0.0)
      end

      it "matches a few hours a week against weekly programmes" do
        weekly = build_org(volunteer_frequency: ["Weekly", "Ongoing"])

        expect(score_for(weekly, volunteer("few_hours"))[:earned]).to eq(3.0)
      end

      it "scores nothing when the user is unsure" do
        org = build_org(volunteer_frequency: ["Ongoing"])

        expect(score_for(org, volunteer("not_sure"))[:max]).to eq(0.0)
      end
    end

    describe "leadership attributes" do
      it "matches either attribute against the combined question" do
        women = build_org(leadership_attributes: ["Women-led"])
        bipoc = build_org(name: "BIPOC Led", ein_number: "aa041", leadership_attributes: ["BIPOC-led"])
        neither = build_org(name: "Neither", ein_number: "aa042", leadership_attributes: [])

        answers = intent(prefs: ["women_bipoc_led"])

        expect(score_for(women, answers)[:earned]).to eq(1.0) # 2 x 0.5
        expect(score_for(bipoc, answers)[:earned]).to eq(1.0)
        # An empty array is "not answered", not "neither" -- see the migration.
        expect(score_for(neither, answers)[:max]).to eq(0.0)
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

  # These organizations record no beneficiary subcategories by design -- the
  # flag replaces enumerating them. Before this, every population rule scored
  # them 0, so an org serving everyone (including the user) ranked below one
  # that ticked a matching box.
  describe "organizations serving the general population" do
    it "gives partial credit where an exact population match would score full" do
      general = build_org(general_population_serving: true)
      exact = build_org(name: "Seniors Specialist", ein_number: "880011",
        beneficiaries: ["Seniors"])

      answers = intent(self_description: ["senior"])

      general_earned = score_for(general, answers)[:earned]
      exact_earned = score_for(exact, answers)[:earned]

      expect(general_earned).to be > 0, "serving everyone should not score zero"
      expect(general_earned).to be < exact_earned, "it is a weaker signal than specialising"
      expect(general_earned).to eq(exact_earned * 0.5)
    end

    it "records how the credit was earned in the trace" do
      general = build_org(general_population_serving: true)

      entry = score_for(general, intent(self_description: ["senior"]))[:matched]
        .find { |m| m[:field] == "population" }

      expect(entry[:via]).to eq("general_population_serving")
    end

    it "prefers an exact match over the general-population credit" do
      both = build_org(general_population_serving: true, beneficiaries: ["Seniors"])

      entry = score_for(both, intent(self_description: ["senior"]))[:matched]
        .find { |m| m[:field] == "population" }

      expect(entry[:via]).to be_nil, "an exact match should not be downgraded"
    end

    it "does not extend the credit to non-population fields" do
      general = build_org(general_population_serving: true)

      # A cause rule must still require an actual cause match.
      result = score_for(general, intent(causes: ["Mental Health"]))

      expect(result[:matched].map { |m| m[:field] }).not_to include("cause")
    end

    it "leaves ordinary organizations untouched" do
      plain = build_org(beneficiaries: ["Seniors"])

      entry = score_for(plain, intent(self_description: ["senior"]))[:matched].first

      expect(entry[:contribution]).to eq(7.5)
      expect(entry[:via]).to be_nil
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

  # Feeds the results page's "how we matched you" panel. The three states are
  # user-facing, so the distinction between "does not offer this" and "has not
  # told us" has to survive out of the scorer.
  describe "criteria reporting" do
    def criteria_for(org, user_intent)
      score_for(org, user_intent)[:criteria].to_h { |c| [[c[:question], c[:answer]], c[:status]] }
    end

    it "marks a satisfied answer as met" do
      org = build_org(beneficiaries: ["Seniors"])

      expect(criteria_for(org, intent(self_description: ["senior"])))
        .to include(["self_description", "senior"] => "met")
    end

    it "marks an answer the organization does not satisfy as unmet" do
      org = build_org(beneficiaries: ["Veterans"])

      expect(criteria_for(org, intent(self_description: ["senior"])))
        .to include(["self_description", "senior"] => "unmet")
    end

    # The case the panel exists for: the organization has never recorded an
    # answer, which is not the same as answering no.
    it "marks an unanswered capability as unknown rather than unmet" do
      org = build_org # wheelchair_accessible is NULL

      expect(criteria_for(org, intent(prefs: ["wheelchair_accessible"])))
        .to include(["prefs", "wheelchair_accessible"] => "unknown")
    end

    it "marks an explicitly-declined capability as unmet" do
      org = build_org
      org.locations.first.update_columns(wheelchair_accessible: false)

      expect(criteria_for(org.reload, intent(prefs: ["wheelchair_accessible"])))
        .to include(["prefs", "wheelchair_accessible"] => "unmet")
    end

    it "reports every answer the user gave" do
      org = build_org(beneficiaries: ["Seniors"], causes: ["Seniors"])

      criteria = criteria_for(org, intent(
        self_description: %w[senior veteran],
        causes: ["Seniors"],
        prefs: ["wheelchair_accessible"]
      ))

      expect(criteria.keys).to include(
        ["self_description", "senior"],
        ["self_description", "veteran"],
        ["causes", "Seniors"],
        ["prefs", "wheelchair_accessible"]
      )
    end

    # Only what the user actually chose is reported. Capability preferences in
    # particular will read "not stated" for a long time, so it matters that a
    # preference the user never ticked can't appear at all.
    it "reports nothing for questions the user did not answer" do
      org = build_org(beneficiaries: ["Seniors"])

      criteria = criteria_for(org, intent(self_description: ["senior"]))

      expect(criteria.keys.map(&:first)).to eq(["self_description"])
      expect(criteria.keys).not_to include(
        ["prefs", "no_id_required"],
        ["prefs", "multilingual"],
        ["prefs", "wheelchair_accessible"]
      )
    end

    # "No preference" is not something the user asked for, so it should not
    # appear as a criterion they can see unmet.
    it "omits escape-hatch answers" do
      org = build_org

      criteria = criteria_for(org, intent(self_description: ["none"], prefs: ["none"]))

      expect(criteria.keys).not_to include(["self_description", "none"], ["prefs", "none"])
    end

    # Services collapse into a single row rather than one per service: a
    # six-service selection produced six rows, which buried everything else.
    it "reports all chosen services as one grouped criterion" do
      org = build_org(services: ["Homeless Shelters"])

      criteria = score_for(org, intent(services: ["Homeless Shelters", "Temporary Housing"]))[:criteria]
      services = criteria.find { |c| c[:question] == "services" }

      expect(services[:answer]).to be_nil
      expect(services[:grouped]).to be(true)
      expect(services[:status]).to eq("partial")
      expect(services[:matched_count]).to eq(1)
      expect(services[:selected_count]).to eq(2)
    end

    it "reports a fully-covered service selection as met" do
      org = build_org(services: ["Homeless Shelters", "Temporary Housing"])

      services = score_for(org, intent(services: ["Homeless Shelters", "Temporary Housing"]))[:criteria]
        .find { |c| c[:question] == "services" }

      expect(services[:status]).to eq("met")
      expect(services[:matched_count]).to eq(2)
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
