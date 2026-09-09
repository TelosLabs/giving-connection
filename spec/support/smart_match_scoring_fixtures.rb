# frozen_string_literal: true

# Shared, fully-deterministic fixture set for Smart Match scoring specs.
#
# Built for the scoring refinement (see docs/smart-match-scoring/). Two things
# live here so the baseline characterization spec and the RuleScorer specs
# score the *same* organizations against the *same* answers -- otherwise a
# ranking diff between phases tells you nothing.
#
# Determinism matters more than realism here. Nothing uses Faker, factory
# sequences, or random embeddings: cosine distances come from a fixed formula
# keyed on the organization's position in ORGANIZATIONS, so the only thing that
# can move a score between runs is a change to the scoring code itself.
module SmartMatchScoringFixtures
  module_function

  # Organizations chosen to span the dimensions the client's scoring sheet
  # cares about: each of the three lookup sheets' major answers, plus a
  # deliberately generic org (matches nothing) and two non-Regional scopes.
  #
  # Preset names are exact values from Organizations::Constants -- a typo here
  # silently produces a zero-scoring org and a misleading baseline.
  ORGANIZATIONS = [
    {
      key: "youth",
      name: "Youth Futures Collective",
      ntee: "P30: Children & Youth Services",
      scope: "Regional",
      causes: ["Youth Development", "Children & Family Services"],
      beneficiaries: ["Children & Youth", "Individuals Under 21"],
      services: ["Youth Specific Services", "Children & Family Services"]
    },
    {
      key: "housing",
      name: "Safe Harbor Shelter",
      ntee: "L41: Homeless Shelters",
      scope: "Regional",
      causes: ["Housing & Homelessness"],
      beneficiaries: ["People Struggling with Homelessness", "Economically Disadvantaged People"],
      services: ["Homeless Shelters", "Housing Support Services"]
    },
    {
      key: "senior",
      name: "Golden Years Center",
      ntee: "P81: Senior Centers",
      scope: "Regional",
      causes: ["Seniors"],
      beneficiaries: ["Seniors", "Retired People"],
      services: ["Senior Centers", "Senior Services & Programs"]
    },
    {
      key: "veteran",
      name: "Veterans Bridge Network",
      ntee: "W30: Military & Veterans Organizations",
      scope: "National",
      causes: ["Veteran & Military"],
      beneficiaries: ["Veterans", "Military Personnel"],
      services: ["Veteran & Military Support Services"]
    },
    {
      key: "mental_health",
      name: "Clearwater Counseling",
      ntee: "F20: Substance Abuse Dependency, Prevention & Treatment",
      scope: "Regional",
      causes: ["Mental Health", "Drug & Alcohol Treatment"],
      beneficiaries: ["People with Mental Health Issues", "People with Substance Abuse Issues"],
      services: ["Mental Health Counseling", "Addiction & Recovery Services"]
    },
    {
      key: "lgbtq",
      name: "Open Door Alliance",
      ntee: "P88: LGBT Centers",
      scope: "Regional",
      causes: ["LGBTQ+"],
      beneficiaries: ["LGBTQ+ People"],
      services: ["LGBTQ+ Community Centers", "LGBTQ+ Advocacy"]
    },
    {
      key: "racial_equity",
      name: "Equity Forward",
      ntee: "R22: Minority Rights",
      scope: "National",
      causes: ["Race & Ethnicity"],
      beneficiaries: ["People of African Descent", "People of all Racial Minority Groups"],
      services: ["Racial Justice Advocacy & Policy", "Racial Equity & Equality Advocacy"]
    },
    {
      key: "generic",
      name: "Riverside Arts Guild",
      ntee: "A90: Arts Services",
      scope: "Regional",
      causes: ["Arts & Culture"],
      beneficiaries: [],
      services: []
    }
  ].freeze

  # Session-answer hashes, exactly as QuizNavigator would leave them.
  #
  # Deliberately built through UserIntent.from_session rather than
  # UserIntent.new: several scenarios carry answers (self_description,
  # donor_communities, volunteer_type, ...) that UserIntent ignored before
  # Phase 1. Routing through from_session means the same fixtures keep working
  # as those answers start being read, and the baseline diff shows exactly what
  # carrying them changed.
  SCENARIOS = [
    {
      key: "seeker_unhoused_nashville",
      user_type: "service_seeker",
      answers: {
        state: "TN", city: "Nashville", location_scope: "local", travel_bucket: "nearby",
        support_for: "myself",
        causes: ["Housing & Homelessness"],
        self_description: ["currently_unhoused", "economically_disadvantaged"],
        situation: "urgent",
        prefs: ["free_sliding_scale", "no_id_required"],
        age_range: "35_44"
      }
    },
    {
      key: "seeker_mental_health_veteran",
      user_type: "service_seeker",
      answers: {
        state: "TN", city: "Nashville", location_scope: "local", travel_bucket: "moderate",
        support_for: "myself",
        causes: ["Mental Health"],
        self_description: ["mental_health", "veteran"],
        prefs: ["none"],
        age_range: "45_54"
      }
    },
    {
      key: "seeker_family_los_angeles",
      user_type: "service_seeker",
      answers: {
        state: "CA", city: "Los Angeles", location_scope: "local", travel_bucket: "far",
        support_for: "someone_else",
        causes: ["Children & Family Services"],
        self_description: ["children_youth", "caregiver"],
        prefs: ["wheelchair_accessible", "multilingual"],
        age_range: "25_34"
      }
    },
    {
      key: "seeker_lgbtq_nationwide",
      user_type: "service_seeker",
      answers: {
        location_scope: "national",
        support_for: "myself",
        causes: ["LGBTQ+"],
        self_description: ["lgbtqia"],
        prefs: ["lgbtqia_affirming"]
      }
    },
    {
      key: "donor_veteran_national",
      user_type: "donor",
      answers: {
        location_scope: "national",
        causes: ["Veteran & Military"],
        donation_style: ["general_donation"],
        donor_communities: ["veteran_military"],
        impact_location: "anywhere"
      }
    },
    {
      key: "donor_bipoc_nashville",
      user_type: "donor",
      answers: {
        state: "TN", city: "Nashville", location_scope: "local",
        causes: ["Race & Ethnicity"],
        donation_style: ["recurring_giving"],
        donor_communities: ["bipoc"],
        impact_location: "near_me"
      }
    },
    {
      key: "volunteer_seniors_nashville",
      user_type: "volunteer",
      answers: {
        state: "TN", city: "Nashville", location_scope: "local",
        causes: ["Seniors"],
        volunteer_involvement: ["volunteer_time"],
        volunteer_type: ["kids_seniors"],
        volunteer_format: "in_person",
        volunteer_time: "ongoing"
      }
    },
    {
      key: "volunteer_no_preference_la",
      user_type: "volunteer",
      answers: {
        state: "CA", city: "Los Angeles", location_scope: "local",
        causes: ["Education"],
        volunteer_involvement: ["just_exploring"],
        volunteer_type: ["no_preference"],
        volunteer_format: "both",
        volunteer_time: "not_sure"
      }
    }
  ].freeze

  # Fixed pseudo-retrieval values. Every scenario sees the same distances, so
  # any per-scenario difference in the output is attributable to scoring alone.
  def cosine_distance_for(index)
    (0.20 + (index * 0.05)).round(4)
  end

  def distance_miles_for(index)
    3 + (index * 7)
  end

  # Creates the eight organizations with exact preset tagging. Causes,
  # beneficiary subcategories, and services are memoized per name so orgs share
  # rows the way they do in production (and so `intersect?` checks behave the
  # same way).
  def create_organizations!
    ORGANIZATIONS.each_with_index.map do |spec, index|
      organization = FactoryBot.create(
        :organization,
        name: spec[:name],
        ein_number: "9900#{index}",
        irs_ntee_code: spec[:ntee],
        scope_of_work: spec[:scope]
      )

      # The factory attaches a random Faker-named cause on build; replace it
      # wholesale so tagging is exactly what the spec declares.
      organization.causes = spec[:causes].map { |name| find_or_create_cause(name) }
      organization.beneficiary_subcategories =
        spec[:beneficiaries].map { |name| find_or_create_beneficiary(name) }

      location = organization.locations.first
      location.services = spec[:services].map { |name| find_or_create_service(name) }

      organization.reload
    end
  end

  def find_or_create_cause(name)
    Cause.find_or_create_by!(name: name)
  end

  def find_or_create_service(name)
    Service.find_or_create_by!(name: name) do |service|
      service.cause = find_or_create_cause("Human & Social Services")
    end
  end

  def find_or_create_beneficiary(name)
    BeneficiarySubcategory.find_or_create_by!(name: name) do |subcategory|
      subcategory.beneficiary_group = BeneficiaryGroup.find_or_create_by!(name: "Fixtures")
    end
  end

  # Candidate hashes in the shape SimilarityQuery returns, without touching
  # pgvector or the embedding service.
  def candidates_for(organizations)
    organizations.each_with_index.map do |organization, index|
      {
        organization_embedding: FactoryBot.create(:organization_embedding, organization: organization),
        cosine_distance: cosine_distance_for(index),
        distance_miles: distance_miles_for(index)
      }
    end
  end

  def user_intent_for(scenario)
    UserIntent.from_session(
      session_answers: scenario[:answers],
      user_type: scenario[:user_type]
    )
  end
end
