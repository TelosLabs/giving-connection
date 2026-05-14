# frozen_string_literal: true

require "rails_helper"

# Integration coverage for the Smart Match wizard. Stands in for a Capybara+JS
# system spec: the JS-side regressions are covered by Stimulus controller specs,
# and the high-value wiring regressions (controller -> service -> model ->
# render) are catchable here without the chromedriver/Capybara infrastructure
# lift. External calls are stubbed at the SmartMatch::EmbeddingClient and
# SmartMatch::SimilarityQuery class-method seams; no real HTTP is issued.
RSpec.describe "SmartMatch quiz flow", type: :request do
  let(:vector) { Array.new(1024) { 0.1 } }

  before do
    Rails.cache.clear
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
  end

  describe "GET /smart_match (landing)" do
    it "renders without auth and includes the localized hero title" do
      get smart_match_root_path

      expect(response).to have_http_status(:ok)
      expect(response).not_to redirect_to(new_user_session_path)
      expect(response.body).to include(I18n.t("smart_match.landing.hero.title"))
    end
  end

  describe "GET /smart_match/quiz" do
    it "renders step 1 and seeds the session step when not set" do
      get smart_match_quiz_path

      expect(response).to have_http_status(:ok)
      # Session is implicitly step 1 (controller reads
      # `(session[:smart_match_step] || 1).to_i`). After a subsequent forward
      # navigation, we can confirm the increment from 1 -> 2.
      put smart_match_quiz_path, params: {user_type: "donor"}
      expect(request.session[:smart_match_step]).to eq(2)
      expect(request.session[:smart_match_user_type]).to eq("donor")
    end
  end

  describe "donor quiz happy path (9 steps)" do
    it "advances every step and redirects to confirmation on completion" do
      get smart_match_quiz_path

      # Step 1 -> 2: user_type
      put smart_match_quiz_path, params: {user_type: "donor"}
      expect(response).to redirect_to(smart_match_quiz_path)
      expect(request.session[:smart_match_user_type]).to eq("donor")
      expect(request.session[:smart_match_step]).to eq(2)

      # Step 2 -> 3: causes (multi-select)
      put smart_match_quiz_path, params: {causes: %w[Education Health]}
      expect(request.session[:smart_match_causes]).to eq(%w[Education Health])
      expect(request.session[:smart_match_step]).to eq(3)

      # Step 3 -> 4: donation_style (multi-select)
      put smart_match_quiz_path, params: {donation_style: %w[one_time]}
      expect(request.session[:smart_match_donation_style]).to eq(%w[one_time])
      expect(request.session[:smart_match_step]).to eq(4)

      # Step 4 -> 5: giving_inspiration (multi-select)
      put smart_match_quiz_path, params: {giving_inspiration: %w[personal_story]}
      expect(request.session[:smart_match_giving_inspiration]).to eq(%w[personal_story])
      expect(request.session[:smart_match_step]).to eq(5)

      # Step 5 -> 6: donor_communities (multi-select)
      put smart_match_quiz_path, params: {donor_communities: %w[veterans]}
      expect(request.session[:smart_match_donor_communities]).to eq(%w[veterans])
      expect(request.session[:smart_match_step]).to eq(6)

      # Step 6 -> 7: impact_location (single)
      put smart_match_quiz_path, params: {impact_location: "local"}
      expect(request.session[:smart_match_impact_location]).to eq("local")
      expect(request.session[:smart_match_step]).to eq(7)

      # Step 7 -> 8: city_selection — also sets state via centroid lookup
      put smart_match_quiz_path, params: {city_selection: "Nashville"}
      expect(request.session[:smart_match_city]).to eq("Nashville")
      expect(request.session[:smart_match_state]).to eq("TN")
      expect(request.session[:smart_match_step]).to eq(8)

      # Step 8 -> 9: donor_involvement (single)
      put smart_match_quiz_path, params: {donor_involvement: "active"}
      expect(request.session[:smart_match_donor_involvement]).to eq("active")
      expect(request.session[:smart_match_step]).to eq(9)

      # Step 9 (final): personal details + language_input — completes the quiz
      put smart_match_quiz_path, params: {
        age_range: "25-34",
        gender_identity: "prefer_not_to_say",
        race_ethnicity: "prefer_not_to_say",
        language_input: "I want my donations to support education in Nashville."
      }
      expect(response).to redirect_to(smart_match_confirmation_path)
    end
  end

  describe "back navigation" do
    it "decrements the step when direction=back" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      expect(request.session[:smart_match_step]).to eq(3)

      put smart_match_quiz_path, params: {direction: "back"}
      expect(request.session[:smart_match_step]).to eq(2)
      expect(response).to redirect_to(smart_match_quiz_path)
    end
  end

  describe "DELETE /smart_match/quiz (reset)" do
    it "clears all smart_match_* session keys and redirects to landing" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      expect(request.session.keys.any? { |k| k.to_s.start_with?("smart_match_") }).to be true

      delete smart_match_quiz_path

      expect(response).to redirect_to(smart_match_root_path)
      smart_match_keys = request.session.keys.select { |k| k.to_s.start_with?("smart_match_") }
      expect(smart_match_keys).to be_empty
    end
  end

  describe "GET /smart_match/confirmation" do
    it "renders the confirmation page with a completed session" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}

      get smart_match_confirmation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.confirmation.title"))
    end
  end

  describe "GET /smart_match/result" do
    let(:organization) { create(:organization) }
    let(:organization_embedding) { create(:organization_embedding, organization: organization) }

    def prime_donor_session
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      put smart_match_quiz_path, params: {donation_style: %w[one_time]}
      put smart_match_quiz_path, params: {giving_inspiration: %w[personal_story]}
      put smart_match_quiz_path, params: {donor_communities: %w[veterans]}
      put smart_match_quiz_path, params: {impact_location: "local"}
      put smart_match_quiz_path, params: {city_selection: "Nashville"}
      put smart_match_quiz_path, params: {donor_involvement: "active"}
      put smart_match_quiz_path, params: {
        age_range: "25-34", gender_identity: "prefer_not_to_say",
        race_ethnicity: "prefer_not_to_say",
        language_input: "Support education in Nashville."
      }
    end

    it "renders the org card and persists a QuizSubmission on the happy path" do
      organization_embedding # touch to create org + embedding before stub

      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return([
        {organization_embedding: organization_embedding, cosine_distance: 0.1, distance_miles: 5.0}
      ])

      prime_donor_session

      expect {
        get smart_match_result_path
      }.to change(QuizSubmission, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(organization.name)
    end

    it "renders the unavailable fallback when EmbeddingClient raises EmbeddingUnavailableError" do
      allow(SmartMatch::EmbeddingClient).to receive(:call)
        .and_raise(SmartMatch::EmbeddingUnavailableError, "boom")

      prime_donor_session

      get smart_match_result_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.results.unavailable.title"))
    end

    it "redirects to landing with a flash when submission_id is stale" do
      prime_donor_session

      # Forge a stale submission id in the session via the quiz controller —
      # in request specs we cannot set session keys directly, so we make a
      # request that we know writes a known key, then mutate by using the
      # ActionDispatch test infrastructure: simplest path is to stub
      # QuizSubmission.find_by to mimic a missing row.
      #
      # The behavior under test is: when session[:smart_match_submission_id]
      # is set but the row has been deleted, the controller deletes the
      # session key, sets flash[:alert], and redirects to the root.
      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return([])

      # First request creates the submission and stores its id in session.
      get smart_match_result_path
      submission = QuizSubmission.last
      expect(submission).to be_present
      expect(response).to have_http_status(:ok)

      # Now delete the submission row so the cached id is stale.
      submission.destroy!

      get smart_match_result_path
      expect(response).to redirect_to(smart_match_root_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects back to the quiz when a forced step 9 submit fails UserIntent validation" do
      get smart_match_quiz_path
      # Pick a user_type so we know total_steps = 9, but leave state and
      # causes blank — UserIntent.valid? will fail on missing state + causes.
      put smart_match_quiz_path, params: {user_type: "donor"}

      # Jump straight to the final step by submitting direction=next many
      # times without filling in required fields. The first valid back-end
      # gate is at "completion" (step > total_steps), so we need to force
      # the controller's current_step to 9. Without modifying app code, the
      # cleanest path is to drive the navigator to step 9 by submitting
      # empty next params from step 2 through step 9.
      7.times do
        put smart_match_quiz_path, params: {}
      end
      expect(request.session[:smart_match_step]).to eq(9)

      # Step 9 next -> completion check runs, UserIntent invalid (no state,
      # no causes_selected), so controller redirects back to quiz with flash.
      put smart_match_quiz_path, params: {}
      expect(response).to redirect_to(smart_match_quiz_path)
      expect(flash[:alert]).to be_present
    end
  end
end
