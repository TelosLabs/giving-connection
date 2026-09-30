# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::Searchable do
  describe ".search_by_keyword" do
    it "matches an organization by its accepted in-kind donation items" do
      organization = create(:organization, in_kind_donation_items: ["towels_washcloths"])
      location = organization.locations.first

      expect(Location.search_by_keyword("towels")).to include(location)
    end

    it "does not match organizations that do not accept the searched item" do
      organization = create(:organization, in_kind_donation_items: ["diapers"])
      location = organization.locations.first

      expect(Location.search_by_keyword("towels")).not_to include(location)
    end
  end
end
