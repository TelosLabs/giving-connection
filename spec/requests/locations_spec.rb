# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locations", type: :request do
  describe "GET /locations/:id" do
    # The page renders the shared search bar via `form_with scope: :search`.
    # `locations#show` never assigns `@search`, so passing it as `model:` blew
    # up on Rails 8 ("Passed nil to the :model argument"). Nothing rendered
    # this page in the suite, so the 500 only showed up in a browser.
    it "renders for an anonymous visitor" do
      location = create(:location, :with_office_hours)

      get location_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(location.name)
    end

    it "renders the search bar form scoped to :search" do
      location = create(:location, :with_office_hours)

      get location_path(location)

      expect(response.body).to include('id="search-bar"')
      expect(response.body).to include('name="search[keyword]"')
    end
  end
end
