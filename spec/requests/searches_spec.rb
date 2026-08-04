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
      expect(response.body).to include("submit-&gt;search-tracking#trackSearch")
        .or include("submit->search-tracking#trackSearch")
    end

    # SearchesController#show renders a *different* template (_preview.html.slim,
    # with its own copy of the search form) when there's no referrer from a prior
    # search and no search params — exactly what a first-time visitor (and
    # Capybara's `visit search_path`) hits. The spec above only exercises the
    # params-present path, which renders show.html.slim, so it never actually
    # covered this template. Both need the tracking action wired.
    it "wires the paramless preview template's search form the same way" do
      get "/search"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("submit-&gt;search-tracking#trackSearch")
        .or include("submit->search-tracking#trackSearch")
    end
  end
end
