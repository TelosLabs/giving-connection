# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searches", type: :request do
  describe "GET /search" do
    it "wires the search form to fire the Stimulus search-tracking action on submit" do
      get "/search", params: {search: {keyword: "food pantry"}}

      expect(response).to have_http_status(:ok)
      # The actual dataLayer push is verified end-to-end in
      # spec/system/search_analytics_system_spec.rb (needs a real browser to run JS).
      # This just confirms the server renders the wiring that action depends on.
      expect(response.body).to include("submit-&gt;search#trackSearch").or include("submit->search#trackSearch")
    end
  end
end
