# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SmartMatch::Quizzes", type: :request do
  describe "GET /smart_match/quiz" do
    it "renders the quiz page" do
      get smart_match_quiz_path

      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      get smart_match_quiz_path

      expect(response).not_to redirect_to(new_user_session_path)
    end

    it "shows step 1 by default" do
      get smart_match_quiz_path

      expect(response.body).to include("Step 1 of")
    end
  end

  describe "PUT /smart_match/quiz" do
    it "stores user type in session and advances step" do
      put smart_match_quiz_path, params: {user_type: "volunteer"}

      expect(response).to redirect_to(smart_match_quiz_path)
    end

    it "stores location data and advances step" do
      put smart_match_quiz_path, params: {user_type: "volunteer"}
      put smart_match_quiz_path, params: {state: "TN", city: "Nashville", travel_bucket: "moderate"}

      expect(response).to redirect_to(smart_match_quiz_path)
    end

    it "navigates back when direction is back" do
      put smart_match_quiz_path, params: {user_type: "volunteer"}
      put smart_match_quiz_path, params: {direction: "back"}

      expect(response).to redirect_to(smart_match_quiz_path)
    end

    it "redirects to results on quiz completion" do
      # Volunteer has 4 steps
      put smart_match_quiz_path, params: {user_type: "volunteer"}
      put smart_match_quiz_path, params: {state: "TN", city: "Nashville", travel_bucket: "moderate"}
      put smart_match_quiz_path, params: {causes: ["Education", "Health"]}
      put smart_match_quiz_path, params: {language_input: "I want to help"}

      expect(response).to redirect_to(smart_match_results_path)
    end
  end
end
