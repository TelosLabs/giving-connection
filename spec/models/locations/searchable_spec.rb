# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::Searchable do
  # search_vector is precomputed and indexed (not live-computed per request
  # anymore -- see Locations::Searchable::TSVECTOR_SQL), so a location only
  # becomes findable once something calls refresh. In production that's
  # Locations::RefreshSearchVectorJob via model callbacks; here it's explicit
  # so each example's dependency on "the index must be refreshed" is visible.
  def refresh!(location)
    Location.refresh_search_vector!([location.id])
    location.reload
  end

  describe ".search_by_keyword" do
    it "matches an organization by its accepted in-kind donation items" do
      organization = create(:organization, in_kind_donation_items: ["towels_washcloths"])
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("towels")).to include(location)
    end

    it "does not match organizations that do not accept the searched item" do
      organization = create(:organization, in_kind_donation_items: ["diapers"])
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("towels")).not_to include(location)
    end

    it "matches on the location's own address" do
      organization = create(:organization)
      location = refresh!(organization.locations.first.tap { |l| l.update!(address: "742 Evergreen Terrace") })

      expect(Location.search_by_keyword("evergreen")).to include(location)
    end

    it "matches on a service name" do
      cause = Cause.find_or_create_by!(name: "Education")
      service = Service.find_or_create_by!(name: "Tutoring", cause: cause)
      organization = create(:organization)
      location = organization.locations.first
      location.services << service
      refresh!(location)

      expect(Location.search_by_keyword("tutoring")).to include(location)
    end

    it "matches on an organization tag" do
      organization = create(:organization)
      organization.tags.create!(name: "wheelchair accessible")
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("wheelchair")).to include(location)
    end

    it "matches on the organization's mission statement" do
      organization = create(:organization, mission_statement_en: "unique mission statement phrase")
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("phrase")).to include(location)
    end

    it "matches on a social media field" do
      # A plain value, not a URL: Postgres's text search parser tokenizes
      # URLs into path-like lexemes (e.g. "/uniquehandle" from a facebook.com
      # URL), which wouldn't match a plain-word search -- true both before
      # and after this refactor, not something to test here.
      organization = create(:organization)
      organization.create_social_media!(facebook: "uniquehandlexyz")
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("uniquehandlexyz")).to include(location)
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
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("religion")).to include(location)
    end

    it "does not match a cause synonym belonging to a different cause" do
      cause = Cause.find_or_create_by!(name: "Health")
      organization = create(:organization)
      organization.causes << cause
      location = refresh!(organization.locations.first)

      expect(Location.search_by_keyword("religion")).not_to include(location)
    end

    it "does not match a location whose search_vector hasn't been refreshed yet" do
      organization = create(:organization, name: "Findable Only After Refresh")
      location = organization.locations.first

      expect(location.search_vector).to be_nil
      expect(Location.search_by_keyword("Findable")).not_to include(location)
    end
  end

  describe ".refresh_search_vector!" do
    it "does nothing for a blank id list" do
      expect { Location.refresh_search_vector!([]) }.not_to raise_error
      expect { Location.refresh_search_vector!(nil) }.not_to raise_error
    end

    it "picks up changes on re-refresh" do
      organization = create(:organization, name: "Original Name")
      location = refresh!(organization.locations.first)
      expect(Location.search_by_keyword("Original")).to include(location)

      organization.update!(name: "Renamed Org")
      refresh!(location)

      expect(Location.search_by_keyword("Original")).not_to include(location)
      expect(Location.search_by_keyword("Renamed")).to include(location)
    end

    it "only touches the requested locations" do
      organization = create(:organization, name: "Untouched Org")
      location = organization.locations.first

      Location.refresh_search_vector!([-1])

      expect(location.reload.search_vector).to be_nil
    end
  end
end
