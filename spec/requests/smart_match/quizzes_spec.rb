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

    it "shows section 1 by default" do
      get smart_match_quiz_path

      expect(response.body).to include("About You")
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

    it "redirects to confirmation on quiz completion" do
      # Volunteer has 8 steps
      put smart_match_quiz_path, params: {user_type: "volunteer"}
      put smart_match_quiz_path, params: {causes: ["Education"]}
      put smart_match_quiz_path, params: {volunteer_involvement: ["Teaching"]}
      put smart_match_quiz_path, params: {volunteer_type: ["In-person"]}
      put smart_match_quiz_path, params: {volunteer_format: "in_person"}
      put smart_match_quiz_path, params: {city_selection: "Nashville"}
      put smart_match_quiz_path, params: {volunteer_time: "few_hours_week"}
      put smart_match_quiz_path, params: {language_input: "I want to help"}

      expect(response).to redirect_to(smart_match_confirmation_path)
    end
  end
end
