# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SmartMatch::Landing", type: :request do
  describe "GET /smart_match" do
    it "renders the landing page" do
      get smart_match_root_path

      expect(response).to have_http_status(:ok)
    end

    it "does not require authentication" do
      get smart_match_root_path

      expect(response).not_to redirect_to(new_user_session_path)
    end

    it "displays the get started link" do
      get smart_match_root_path

      expect(response.body).to include("START")
    end
  end
end
