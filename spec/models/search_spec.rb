# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search do
  def location_for(**organization_attrs)
    @org_counter = @org_counter.to_i + 1
    create(:organization, name: "organization #{@org_counter}", **organization_attrs).locations.first
  end

  describe "#execute_search" do
    let!(:donation) { location_for(donation_link: "https://example.org/donate") }
    let!(:both) do
      location_for(
        donation_link: "https://example.org/donate",
        volunteer_availability: true,
        volunteer_link: "https://example.org/volunteer"
      )
    end
    let!(:nothing) { location_for }

    it "applies the give filter" do
      search = described_class.new(city: "Search all", give: [Search::GIVE_DONATION])
      search.save

      expect(search.results.ids).to contain_exactly(donation.id, both.id)
    end

    it "orders give results by how many give options they match" do
      search = described_class.new(
        city: "Search all", give: [Search::GIVE_DONATION, Search::GIVE_VOLUNTEER]
      )
      search.save

      expect(search.results.ids.first).to eq(both.id)
    end

    # Regression: in_order_of was applied unconditionally, so its CASE ordering
    # assigned every row a unique sort position and pg_search's relevance rank
    # could never break a tie. Keyword searches lost relevance ordering.
    it "does not impose the give ordering on keyword searches" do
      search = described_class.new(city: "Search all", keyword: "organization")
      search.save

      expect(search.results.to_sql).not_to include("CASE")
    end

    it "does not impose the give ordering when no give filter is selected" do
      search = described_class.new(city: "Search all")
      search.save

      expect(search.results.to_sql).not_to include("CASE")
    end
  end
end
