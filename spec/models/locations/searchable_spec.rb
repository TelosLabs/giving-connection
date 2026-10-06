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

    # Cause synonyms come from config/matching_rules.yml (the same cause_mappings
    # Smart Match uses), so a search term can match a cause even when it never
    # appears verbatim anywhere on the organization. Uses find_or_create_by!
    # because CI seeds real causes (populate:seed_causes_and_services), so
    # "Faith-Based" and "Health" may already exist.
    it "matches an organization through a cause synonym, not just the cause's literal name" do
      cause = Cause.find_or_create_by!(name: "Faith-Based")
      organization = create(:organization)
      organization.causes << cause
      location = organization.locations.first

      expect(Location.search_by_keyword("religion")).to include(location)
    end

    it "does not match a cause synonym belonging to a different cause" do
      cause = Cause.find_or_create_by!(name: "Health")
      organization = create(:organization)
      organization.causes << cause
      location = organization.locations.first

      expect(Location.search_by_keyword("religion")).not_to include(location)
    end
  end
end
