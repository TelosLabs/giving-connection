# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Location searches", type: :request do
  describe "GET /location_search/suggestions" do
    it "renders server-side <li> options without requiring auth" do
      allow(LocationAutocomplete).to receive(:call).with("nash").and_return([
        { description: "Nashville, TN", place_id: "p1" }
      ])

      get location_suggestions_path, params: { q: "nash" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('role="option"')
      expect(response.body).to include('data-autocomplete-value="Nashville, TN"')
      expect(response.body).to include("Nashville, TN")
    end

    it "renders an empty body when there are no predictions" do
      allow(LocationAutocomplete).to receive(:call).and_return([])

      get location_suggestions_path, params: { q: "zzzzz" }

      expect(response).to have_http_status(:ok)
      expect(response.body.strip).to be_empty
    end
  end

  describe "GET /location_search/geocode" do
    it "returns resolved coordinates as JSON" do
      allow(LocationGeocoder).to receive(:call).with("Nashville").and_return(
        latitude: 36.16, longitude: -86.78, city: "Nashville"
      )

      get location_geocode_path, params: { q: "Nashville" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "latitude" => 36.16, "longitude" => -86.78, "city" => "Nashville"
      )
    end

    it "returns 422 when the location can't be resolved" do
      allow(LocationGeocoder).to receive(:call).and_return(nil)

      get location_geocode_path, params: { q: "nowhere" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
