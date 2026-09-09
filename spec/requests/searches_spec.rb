# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Searches", type: :request do
  # The organization factory builds its own location and is scope_of_work
  # "International", so these locations survive the geo merge too.
  def location_for(**organization_attrs)
    @org_counter = @org_counter.to_i + 1
    create(:organization, name: "organization #{@org_counter}", **organization_attrs).locations.first
  end

  def donating_location
    location_for(donation_link: "https://example.org/donate")
  end

  # All three of city/lat/lon are required before Locationable reads the city
  # from params instead of falling back to Nashville.
  def get_search(search_params, page: nil)
    query = {
      search: {
        city: "Search all",
        lat: Locationable::DEFAULT_LATITUDE,
        lon: Locationable::DEFAULT_LONGITUDE
      }.merge(search_params)
    }
    query[:page] = page if page # pagy reads the page param at the top level

    get search_path, params: query
  end

  describe "GET /search with search[give][]" do
    it "renders results filtered by the give pill without authentication" do
      matching = donating_location
      other = location_for

      get_search({give: [Search::GIVE_DONATION]})

      expect(response).to have_http_status(:ok)
      expect(assigns(:all_result_ids)).to contain_exactly(matching.id)
      expect(assigns(:results).map(&:id)).to contain_exactly(matching.id)
      expect(assigns(:all_result_ids)).not_to include(other.id)
    end

    it "keeps filtering by give on the geolocated path" do
      matching = donating_location
      location_for

      get search_path, params: {search: {give: [Search::GIVE_DONATION]}}

      expect(response).to have_http_status(:ok)
      expect(assigns(:search).city).to eq(Locationable::DEFAULT_CITY)
      expect(assigns(:all_result_ids)).to contain_exactly(matching.id)
    end

    it "composes with a cause pill" do
      cause = create(:cause, name: "Education")
      matching = donating_location
      matching.organization.causes << cause
      donating_location # right give, wrong cause

      get_search({give: [Search::GIVE_DONATION], causes: ["Education"]})

      expect(response).to have_http_status(:ok)
      expect(assigns(:all_result_ids)).to contain_exactly(matching.id)
    end

    it "does not offer a search alert for a give-only search" do
      donating_location

      get_search({give: [Search::GIVE_DONATION]})

      expect(response.body).to include("Search alerts do not support Give filters yet.")
      expect(response.body).not_to include("Create an Alert for this Search")
    end
  end

  describe "GET /search pagination of a give search" do
    # Pagy 9's key is :limit. config/initializers/pagy.rb still sets the 5.x
    # :items key, so the effective page size is Pagy's own default.
    let(:page_size) { Pagy::DEFAULT[:limit] }
    let!(:matching_ids) { Array.new(page_size + 2) { donating_location.id } }

    it "pages through every matching row exactly once" do
      get_search({give: [Search::GIVE_DONATION]})
      first_page = assigns(:results).map(&:id)

      get_search({give: [Search::GIVE_DONATION]}, page: 2)
      second_page = assigns(:results).map(&:id)

      expect(first_page.size).to eq(page_size)
      expect(first_page & second_page).to be_empty
      expect(first_page + second_page).to match_array(matching_ids)
    end

    it "orders every page by rank then id, so the pages are stable" do
      get_search({give: [Search::GIVE_DONATION]})

      expect(assigns(:results).map(&:id)).to eq(matching_ids.sort.first(page_size))
    end
  end

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
