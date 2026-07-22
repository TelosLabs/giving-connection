# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searches", type: :request do
  describe "GET /search" do
    it "renders a Turbo-safe gtag search event for the keyword and city" do
      get "/search", params: { search: { keyword: "food pantry", city: "Boston" } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("if (typeof gtag === \"function\")")
      expect(response.body).to include("gtag(\"event\", \"search\"")
      # Assert the JSON payload is embedded unescaped (valid JS), not HTML-entity-escaped
      expect(response.body).to include('"search_term":"food pantry"')
      expect(response.body).to include('"category":"Find Help"')
      expect(response.body).to include('"location":"Boston"')
      expect(response.body).not_to include("&quot;")
    end
  end
end
