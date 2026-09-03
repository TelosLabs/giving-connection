# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SmartMatch::Results", type: :request do
  describe "GET /smart_match/result" do
    it "renders the results page" do
      get smart_match_result_path

      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      get smart_match_result_path

      expect(response).not_to redirect_to(new_user_session_path)
    end

    it "shows the placeholder content" do
      get smart_match_result_path

      expect(response.body).to include("Your results are ready!")
    end
  end
end
