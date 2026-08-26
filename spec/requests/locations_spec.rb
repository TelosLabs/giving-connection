# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locations", type: :request do
  let(:organization) { create(:organization) }
  let(:location) { organization.main_location }

  describe "GET /locations/:id in-kind donation needs" do
    it "renders the section in both the mobile and desktop columns" do
      organization.update!(in_kind_donation_items: ["diapers"], in_kind_donation_link: "https://example.org/wishlist")

      get location_path(location)

      expect(response.body.scan("In-Kind Donation Needs").size).to eq(2)
      expect(response.body).to include("Diapers (baby &amp; adult)")
      expect(response.body.scan("View in-kind donation needs").size).to eq(2)
    end

    it "routes the link through the external-link interstitial" do
      organization.update!(in_kind_donation_link: "https://example.org/wishlist")

      get location_path(location)

      expect(response.body).to include(redirect_path(target_url: "https://example.org/wishlist"))
    end

    it "renders no link when the stored link is not http(s)" do
      organization.update!(in_kind_donation_items: ["diapers"])
      organization.update_column(:in_kind_donation_link, "javascript:alert(1)")

      get location_path(location)

      expect(response.body).to include("Diapers (baby &amp; adult)")
      expect(response.body).not_to include("View in-kind donation needs")
      expect(response.body).not_to include("javascript:alert(1)")
    end

    it "omits the section entirely when the org has no in-kind needs" do
      get location_path(location)

      expect(response.body).not_to include("In-Kind Donation Needs")
    end
  end
end
