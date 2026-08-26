# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searches", type: :request do
  describe "GET /search" do
    # SearchesController#show renders two different templates with two separate
    # copies of the search form: show.html.slim when search params are present,
    # and _preview.html.slim for a paramless first visit. Both need the wiring.
    {
      "the results template" => {search: {keyword: "food pantry"}},
      "the paramless preview template" => {}
    }.each do |template, params|
      it "wires #{template}'s search form to fire the Stimulus tracking action on submit" do
        get "/search", params: params

        expect(response).to have_http_status(:ok)
        # The dataLayer push itself is verified end-to-end in
        # spec/system/search_analytics_system_spec.rb, which needs a real browser
        # to run the JS. This just confirms the server renders what it depends on.
        expect(Capybara.string(response.body))
          .to have_css("form[data-action*='search-tracking#trackSearch']", visible: :all)
      end
    end

    describe "first-party search term tracking" do
      it "records the term, its result count and where it came from" do
        expect {
          get "/search", params: {search: {keyword: "food pantry"}, search_origin: "search_results"}
        }.to change(SearchTerm, :count).by(1)

        expect(SearchTerm.last).to have_attributes(
          normalized_keyword: "food pantry",
          results_count: 0,
          origin: "search_results"
        )
      end

      it "records nothing for a search with no keyword" do
        expect { get "/search", params: {search: {city: "Nashville"}} }
          .not_to change(SearchTerm, :count)
      end

      # The regression this whole design exists to prevent: applying a filter
      # re-submits the search form with the keyword unchanged, and counting that
      # as a second search would inflate the top-terms report.
      it "records nothing when the same search is refined by a filter" do
        get "/search", params: {search: {keyword: "food pantry"}}

        expect {
          get "/search", params: {search: {keyword: "food pantry", causes: ["Education"]}}
        }.not_to change(SearchTerm, :count)
      end

      it "records a genuinely new keyword typed after the first search" do
        get "/search", params: {search: {keyword: "food pantry"}}

        expect { get "/search", params: {search: {keyword: "legal aid"}} }
          .to change(SearchTerm, :count).by(1)
      end
    end
  end
end
