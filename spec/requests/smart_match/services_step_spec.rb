# frozen_string_literal: true

require "rails_helper"

# The services step narrows the causes chosen on the previous step to the
# specific services the user needs. It exists because the platform holds ~274
# services under 35 causes, organizations are tagged with them, and the main
# site search already filters on them -- Smart Match was the only surface not
# asking (docs/smart-match-scoring/07-unused-organization-data.md).
RSpec.describe "SmartMatch services step", type: :request do
  def start_donor_quiz(causes)
    get smart_match_quiz_path
    put smart_match_quiz_path, params: {user_type: "donor"}
    put smart_match_quiz_path, params: {causes: causes}
  end

  it "lists only the services belonging to the causes the user chose" do
    start_donor_quiz(%w[Housing\ &\ Homelessness])
    get smart_match_quiz_path

    expect(response.body).to include("Homeless Shelters")
    expect(response.body).to include("Housing Search Assistance")
    # A service from a cause the user did not pick.
    expect(response.body).not_to include("Veteran Trauma Support Services")
  end

  it "groups the services under each chosen cause" do
    start_donor_quiz(["Housing & Homelessness", "Mental Health"])
    get smart_match_quiz_path

    expect(response.body).to include("Housing &amp; Homelessness")
    expect(response.body).to include("Mental Health")
    expect(response.body).to include("Homeless Shelters")
    expect(response.body).to include("Mental Health Counseling")
  end

  # The Stimulus controller toggles a `selected` class on click; the styling
  # for it lives in .sm-pill-option. Conditional Tailwind classes baked in at
  # render time would freeze on the server-rendered state, which is what made
  # selections look unselected.
  it "marks already-chosen services as selected when the step is revisited" do
    start_donor_quiz(["Housing & Homelessness"])
    put smart_match_quiz_path, params: {services: ["Homeless Shelters"]}
    put smart_match_quiz_path, params: {direction: "back"}
    get smart_match_quiz_path

    expect(response.body).to include("sm-pill-option inline-flex items-center selected")
    expect(response.body).to include('value="Homeless Shelters"')
  end

  it "renders unselected services without the selected class" do
    start_donor_quiz(["Housing & Homelessness"])
    get smart_match_quiz_path

    expect(response.body).to include("sm-pill-option")
    expect(response.body).not_to include("sm-pill-option inline-flex items-center selected")
  end

  it "stores the chosen services in the session" do
    start_donor_quiz(["Housing & Homelessness"])
    put smart_match_quiz_path, params: {services: ["Homeless Shelters"]}

    expect(request.session[:smart_match_services]).to eq(["Homeless Shelters"])
  end

  # Some causes (Faith-Based) define no services at all. Showing an empty
  # question would be a dead end, so the navigator skips the step.
  it "skips the step when the chosen causes define no services" do
    start_donor_quiz(["Faith-Based"])

    services_step = SmartMatch::QuizNavigator::SERVICES_STEP["donor"]
    expect(request.session[:smart_match_step]).to be > services_step
  end

  it "shows the step when at least one chosen cause has services" do
    start_donor_quiz(["Faith-Based", "Mental Health"])

    expect(request.session[:smart_match_step])
      .to eq(SmartMatch::QuizNavigator::SERVICES_STEP["donor"])
  end

  describe "scoring" do
    it "rewards an organization offering the exact service chosen" do
      intent = UserIntent.from_session(
        session_answers: {causes: ["Mental Health"], services: ["Mental Health Counseling"]},
        user_type: "donor"
      )

      org = create(:organization)
      org.causes = [Cause.find_or_create_by!(name: "Mental Health")]
      service = Service.find_or_create_by!(name: "Mental Health Counseling") do |s|
        s.cause = Cause.find_or_create_by!(name: "Mental Health")
      end
      org.locations.first.services = [service]

      result = SmartMatch::RuleScorer.call(organization: org.reload, user_intent: intent)

      expect(result[:matched].map { |m| m[:question] }).to include("services")
    end
  end
end
