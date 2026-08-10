# frozen_string_literal: true

require "rails_helper"

# Integration coverage for the Smart Match wizard. Stands in for a Capybara+JS
# system spec: the JS-side regressions are covered by Stimulus controller specs,
# and the high-value wiring regressions (controller -> service -> model ->
# render) are catchable here without the chromedriver/Capybara infrastructure
# lift. External calls are stubbed at the SmartMatch::EmbeddingClient and
# SmartMatch::SimilarityQuery class-method seams; no real HTTP is issued.
RSpec.describe "SmartMatch quiz flow", type: :request do
  include ActiveJob::TestHelper

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

  describe "donor quiz happy path (12 steps, preset city skips the detail step)" do
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

      # Step 3 -> 4: services, scoped to the causes just chosen
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
      expect(request.session[:smart_match_services]).to eq(["Student Educational Services"])
      expect(request.session[:smart_match_step]).to eq(4)

      # Step 4 -> 5: donation_style (multi-select)
      put smart_match_quiz_path, params: {donation_style: %w[one_time]}
      expect(request.session[:smart_match_donation_style]).to eq(%w[one_time])
      expect(request.session[:smart_match_step]).to eq(5)

      # Step 5 -> 6: giving_inspiration (multi-select)
      put smart_match_quiz_path, params: {giving_inspiration: %w[personal_story]}
      expect(request.session[:smart_match_giving_inspiration]).to eq(%w[personal_story])
      expect(request.session[:smart_match_step]).to eq(6)

      # Step 6 -> 7: donor_communities (multi-select)
      put smart_match_quiz_path, params: {donor_communities: %w[veterans]}
      expect(request.session[:smart_match_donor_communities]).to eq(%w[veterans])
      expect(request.session[:smart_match_step]).to eq(7)

      # Step 7 -> 8: impact_location (single)
      put smart_match_quiz_path, params: {impact_location: "local"}
      expect(request.session[:smart_match_impact_location]).to eq("local")
      expect(request.session[:smart_match_step]).to eq(8)

      # city_selection — a preset city derives state via centroid lookup and
      # skips the "Somewhere else" detail step entirely.
      put smart_match_quiz_path, params: {city_selection: "Nashville"}
      expect(request.session[:smart_match_city]).to eq("Nashville")
      expect(request.session[:smart_match_state]).to eq("TN")
      expect(request.session[:smart_match_city_choice]).to eq("Nashville")
      expect(request.session[:smart_match_step])
        .to eq(SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP["donor"] + 1)

      # donor_involvement (single)
      put smart_match_quiz_path, params: {donor_involvement: "active"}
      expect(request.session[:smart_match_donor_involvement]).to eq("active")
      expect(request.session[:smart_match_step]).to eq(11)

      # personal details (optional demographics)
      put smart_match_quiz_path, params: {
        age_range: "25-34",
        gender_identity: "prefer_not_to_say",
        race_ethnicity: "prefer_not_to_say"
      }
      expect(request.session[:smart_match_step]).to eq(12)

      # Step 11 (final): open-ended language_input — completes the quiz
      put smart_match_quiz_path, params: {
        language_input: "I want my donations to support education in Nashville."
      }
      expect(request.session[:smart_match_language]).to eq("I want my donations to support education in Nashville.")
      expect(response).to redirect_to(smart_match_confirmation_path)
    end
  end

  describe "donor 'Somewhere else' path (visits the location detail step)" do
    it "routes through the detail step to capture a state and city" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}                  # 1 -> 2
      put smart_match_quiz_path, params: {causes: %w[Education]}               # 2 -> 3
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
      put smart_match_quiz_path, params: {donation_style: %w[one_time]}        # 3 -> 4
      put smart_match_quiz_path, params: {giving_inspiration: %w[personal_story]} # 4 -> 5
      put smart_match_quiz_path, params: {donor_communities: %w[veterans]}     # 5 -> 6
      put smart_match_quiz_path, params: {impact_location: "local"}            # 6 -> 7

      # The location step renders the "Somewhere else" card alongside cities.
      get smart_match_quiz_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.quiz.steps.city_selection.other"))
      expect(response.body).to include("Atlantic City")

      # Pick "Somewhere else" — routes to the donor detail step.
      put smart_match_quiz_path, params: {city_selection: "elsewhere"}
      expect(request.session[:smart_match_city_choice]).to eq("elsewhere")
      expect(request.session[:smart_match_step])
        .to eq(SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP["donor"])

      # The detail step renders its scope options and US state picker.
      get smart_match_quiz_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.quiz.steps.location_detail.us"))
      expect(response.body).to include(I18n.t("smart_match.quiz.titles.donor.location_detail"))

      # Step 8 (detail): choose the U.S. scope with a state + city.
      put smart_match_quiz_path, params: {location_scope_choice: "local", state: "OR", city: "Portland"}
      expect(request.session[:smart_match_location_scope]).to eq("local")
      expect(request.session[:smart_match_state]).to eq("OR")
      expect(request.session[:smart_match_city]).to eq("Portland")
      expect(request.session[:smart_match_step]).to eq(10)
    end
  end

  describe "service_seeker nationwide scope" do
    it "skips the travel step and completes without a state" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "service_seeker"}        # 1 -> 2
      put smart_match_quiz_path, params: {support_for: "myself"}              # 2 -> 3
      put smart_match_quiz_path, params: {self_description: ["student"]}      # 3 -> 4
      put smart_match_quiz_path, params: {causes: %w[Education]}              # 4 -> 5
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
      put smart_match_quiz_path, params: {situation: "exploring"}            # 5 -> 6

      # city_selection: pick "Somewhere else" → the detail step.
      put smart_match_quiz_path, params: {city_selection: "elsewhere"}
      expect(request.session[:smart_match_step])
        .to eq(SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP["service_seeker"])

      # Step 7 (detail): choose nationwide instead of a specific place.
      put smart_match_quiz_path, params: {location_scope_choice: "national"}
      expect(request.session[:smart_match_location_scope]).to eq("national")
      expect(request.session[:smart_match_state]).to be_nil
      # Travel step (8) is skipped → lands on preferences (9).
      expect(request.session[:smart_match_step]).to eq(10)

      put smart_match_quiz_path, params: {prefs: []}                          # 9 -> 10
      put smart_match_quiz_path, params: {                                    # 10 (personal details) -> 11
        age_range: "25_34", gender_identity: "prefer_not_to_say", race_ethnicity: "prefer_not_to_say"
      }
      expect(request.session[:smart_match_step]).to eq(12)

      put smart_match_quiz_path, params: {language_input: "online job training"}  # 11 -> complete
      expect(response).to redirect_to(smart_match_confirmation_path)
    end
  end

  describe "back navigation" do
    it "decrements the step when direction=back" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
      expect(request.session[:smart_match_step]).to eq(4)

      put smart_match_quiz_path, params: {direction: "back"}
      expect(request.session[:smart_match_step]).to eq(3)
      expect(response).to redirect_to(smart_match_quiz_path)
    end
  end

  describe "DELETE /smart_match/quiz (reset)" do
    it "clears all smart_match_* session keys and restarts the quiz at step 1" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
      expect(request.session.keys.any? { |k| k.to_s.start_with?("smart_match_") }).to be true

      delete smart_match_quiz_path

      expect(response).to redirect_to(smart_match_quiz_path)
      smart_match_keys = request.session.keys.select { |k| k.to_s.start_with?("smart_match_") }
      expect(smart_match_keys).to be_empty
    end

    it "exits to the landing page when return_to=home (quiz X button)" do
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}

      delete smart_match_quiz_path, params: {return_to: "home"}

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
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}

      get smart_match_confirmation_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("smart_match.confirmation.title"))
    end
  end

  describe "GET /smart_match/result" do
    let(:organization) { create(:organization) }
    let(:organization_embedding) { create(:organization_embedding, organization: organization) }
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Matching now runs in ProcessSubmissionJob; the controller and job
      # coordinate through the cache (test env's :null_store won't persist).
      allow(Rails).to receive(:cache).and_return(memory_cache)
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
    end

    def prime_donor_session
      get smart_match_quiz_path
      put smart_match_quiz_path, params: {user_type: "donor"}
      put smart_match_quiz_path, params: {causes: %w[Education]}
      put smart_match_quiz_path, params: {services: ["Student Educational Services"]}
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

    it "enqueues the match job, persists a QuizSubmission when it runs, and renders the org card" do
      organization_embedding # touch to create org + embedding before stub

      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return(
        SmartMatch::SimilarityQuery::Result.new(
          candidates: [
            {organization_embedding: organization_embedding, cosine_distance: 0.1, distance_miles: 5.0}
          ],
          relaxed: []
        )
      )

      prime_donor_session

      # First GET shows the loading state and enqueues the off-thread job.
      expect { get smart_match_result_path }
        .to have_enqueued_job(SmartMatch::ProcessSubmissionJob)
      expect(response.body).to include(I18n.t("smart_match.results.processing.title"))

      # Running the job persists the submission + matches.
      expect { perform_enqueued_jobs }.to change(QuizSubmission, :count).by(1)

      # The next GET (what the poll navigates to) renders the real results.
      get smart_match_result_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(organization.name)
    end

    # Regression guard. The results controller used to build its own 7-key
    # subset of the session for the background job, so answers like
    # donor_communities and donation_style were collected from the user and
    # then silently dropped before scoring. Both controllers now read
    # QuizNavigator.session_answers; this asserts the whole answer set
    # actually survives the trip into the job.
    it "carries every quiz answer through to the persisted submission" do
      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call)
        .and_return(SmartMatch::SimilarityQuery::Result.new(candidates: [], relaxed: []))

      prime_donor_session
      get smart_match_result_path
      perform_enqueued_jobs

      answers = QuizSubmission.last.answers

      expect(answers["donor_communities"]).to eq(%w[veterans])
      expect(answers["donation_style"]).to eq(%w[one_time])
      expect(answers["giving_inspiration"]).to eq(%w[personal_story])
      expect(answers["impact_location"]).to eq("local")
      expect(answers["donor_involvement"]).to eq("active")
      expect(answers["age_range"]).to eq("25-34")
      expect(answers["language_input"]).to eq("Support education in Nashville.")
      expect(answers["city"]).to eq("Nashville")
    end

    it "tells the user when eligibility filters had to be dropped" do
      organization_embedding

      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return(
        SmartMatch::SimilarityQuery::Result.new(
          candidates: [
            {organization_embedding: organization_embedding, cosine_distance: 0.1, distance_miles: 5.0}
          ],
          relaxed: [:donation_link]
        )
      )

      prime_donor_session
      get smart_match_result_path
      perform_enqueued_jobs
      get smart_match_result_path

      expect(response.body).to include(I18n.t("smart_match.results.broadened.title"))
      expect(response.body).to include(I18n.t("smart_match.results.broadened.filters.donation_link"))
    end

    # The transparency panel. A user who asked for wheelchair-accessible
    # services must be able to see that none of their matches offer it, rather
    # than assuming the results honoured the request.
    describe "the how-we-matched-you panel" do
      def render_results_with(criteria)
        allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
        allow(SmartMatch::SimilarityQuery).to receive(:call).and_return(
          SmartMatch::SimilarityQuery::Result.new(
            candidates: [
              {organization_embedding: organization_embedding, cosine_distance: 0.1, distance_miles: 5.0}
            ],
            relaxed: []
          )
        )

        prime_donor_session
        get smart_match_result_path
        perform_enqueued_jobs

        QuizSubmission.last.organization_matches.each do |match|
          match.update!(score_breakdown: match.score_breakdown.merge("criteria" => criteria))
        end

        get smart_match_result_path
      end

      it "lists a criterion no match meets" do
        render_results_with([{"question" => "prefs", "answer" => "wheelchair_accessible", "status" => "unmet"}])

        expect(response.body).to include(I18n.t("smart_match.results.criteria.title"))
        expect(response.body).to include(I18n.t("smart_match.quiz.steps.preferences.options.wheelchair_accessible"))
        expect(response.body).to include(I18n.t("smart_match.results.criteria.status.unmet"))
      end

      it "distinguishes an unanswered criterion from a declined one" do
        render_results_with([{"question" => "prefs", "answer" => "free_sliding_scale", "status" => "unknown"}])

        expect(response.body).to include(I18n.t("smart_match.results.criteria.not_stated"))
        expect(response.body).to include(I18n.t("smart_match.results.criteria.unknown_note"))
        expect(response.body).not_to include(I18n.t("smart_match.results.criteria.status.unmet"))
      end

      it "shows a met criterion" do
        render_results_with([{"question" => "causes", "answer" => "Mental Health", "status" => "met"}])

        expect(response.body).to include("Mental Health")
        expect(response.body).to include(I18n.t("smart_match.results.criteria.status.met"))
      end

      it "omits the panel entirely when there are no criteria" do
        render_results_with([])

        expect(response.body).not_to include(I18n.t("smart_match.results.criteria.title"))
      end
    end

    it "shows no broadened notice when every filter held" do
      organization_embedding

      allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return(
        SmartMatch::SimilarityQuery::Result.new(
          candidates: [
            {organization_embedding: organization_embedding, cosine_distance: 0.1, distance_miles: 5.0}
          ],
          relaxed: []
        )
      )

      prime_donor_session
      get smart_match_result_path
      perform_enqueued_jobs
      get smart_match_result_path

      expect(response.body).not_to include(I18n.t("smart_match.results.broadened.title"))
    end

    it "renders the unavailable fallback when the job hits EmbeddingUnavailableError" do
      allow(SmartMatch::EmbeddingClient).to receive(:call)
        .and_raise(SmartMatch::EmbeddingUnavailableError, "boom")

      prime_donor_session

      # The job records the terminal error; the following GET degrades gracefully.
      perform_enqueued_jobs { get smart_match_result_path }

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
      allow(SmartMatch::SimilarityQuery).to receive(:call)
        .and_return(SmartMatch::SimilarityQuery::Result.new(candidates: [], relaxed: []))

      # Run the job so the submission is persisted, then a GET caches its id
      # into the session (find_submission resolves it by session_id column).
      perform_enqueued_jobs { get smart_match_result_path }
      get smart_match_result_path
      submission = QuizSubmission.last
      expect(submission).to be_present
      expect(response).to have_http_status(:ok)

      # Now delete the submission row so the cached session id is stale.
      submission.destroy!

      get smart_match_result_path
      expect(response).to redirect_to(smart_match_root_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects back to the quiz when a forced final-step submit fails UserIntent validation" do
      get smart_match_quiz_path
      # Pick a user_type so we know total_steps = 11, but leave state and
      # causes blank — UserIntent.valid? will fail on missing state + causes.
      put smart_match_quiz_path, params: {user_type: "donor"}

      # Jump straight to the final step by submitting direction=next many
      # times without filling in required fields. The first valid back-end
      # gate is at "completion" (step > total_steps), so we need to force
      # the controller's current_step to the last step (11). Empty submits
      # never pick "Somewhere else", so the location detail step is skipped —
      # 8 forward moves (2→3…10→11, jumping the detail step) reach the end.
      8.times do
        put smart_match_quiz_path, params: {}
      end
      expect(request.session[:smart_match_step]).to eq(12)

      # Final step next -> completion check runs, UserIntent invalid (no state,
      # no causes_selected), so controller redirects back to quiz with flash.
      put smart_match_quiz_path, params: {}
      expect(response).to redirect_to(smart_match_quiz_path)
      expect(flash[:alert]).to be_present
    end
  end
end
