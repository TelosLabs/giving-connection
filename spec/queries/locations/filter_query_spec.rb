# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::FilterQuery do
  # The organization factory builds its own location, so reach through it
  # rather than creating a second one. Names are unique-validated.
  def location_for(**organization_attrs)
    @org_counter = @org_counter.to_i + 1
    create(:organization, name: "organization #{@org_counter}", **organization_attrs).locations.first
  end

  describe ".by_give" do
    let!(:donation) { location_for(donation_link: "https://example.org/donate") }
    let!(:volunteer) do
      location_for(volunteer_availability: true, volunteer_link: "https://example.org/volunteer")
    end
    let!(:in_kind_link) { location_for(in_kind_donation_link: "https://example.org/wishlist") }
    let!(:in_kind_items) { location_for(in_kind_donation_items: ["diapers", "shoes"]) }
    let!(:nothing) { location_for }

    it "returns scope untouched when no give values are given" do
      expect(described_class.by_give(Location.active, []).ids).to match_array(Location.active.ids)
      expect(described_class.by_give(Location.active, nil).ids).to match_array(Location.active.ids)
    end

    it "ignores give values it does not recognise" do
      expect(described_class.by_give(Location.active, ["Nonsense"]).ids)
        .to match_array(Location.active.ids)
    end

    it "matches organizations with a donation link" do
      expect(described_class.by_give(Location.active, [Search::GIVE_DONATION]).ids)
        .to contain_exactly(donation.id)
    end

    it "matches organizations that are available for volunteering and have a link" do
      location_for(volunteer_availability: false, volunteer_link: "https://example.org/v")
      location_for(volunteer_availability: true, volunteer_link: nil)

      expect(described_class.by_give(Location.active, [Search::GIVE_VOLUNTEER]).ids)
        .to contain_exactly(volunteer.id)
    end

    # Regression: by_give required a link AND items, so organizations that had
    # selected items without adding a wishlist URL showed the In-Kind Donation
    # Needs section on their profile but never matched the pill.
    it "matches in-kind on either a wishlist link or selected items" do
      expect(described_class.by_give(Location.active, [Search::GIVE_IN_KIND]).ids)
        .to contain_exactly(in_kind_link.id, in_kind_items.id)
    end

    it "returns the union when several give pills are selected" do
      ids = described_class.by_give(Location.active, [Search::GIVE_DONATION, Search::GIVE_VOLUNTEER]).ids

      expect(ids).to contain_exactly(donation.id, volunteer.id)
      expect(ids).not_to include(nothing.id)
    end

    it "ranks organizations matching more pills first" do
      everything = location_for(
        donation_link: "https://example.org/donate",
        volunteer_availability: true,
        volunteer_link: "https://example.org/volunteer"
      )

      ids = described_class.by_give(
        Location.active, [Search::GIVE_DONATION, Search::GIVE_VOLUNTEER]
      ).ids

      expect(ids.first).to eq(everything.id)
      expect(ids).to include(donation.id, volunteer.id)
    end

    it "never matches organizations offering none of the selected options" do
      ids = described_class.by_give(Location.active, Search::GIVE_OPTIONS).ids

      expect(ids).not_to include(nothing.id)
    end
  end

  describe ".call" do
    # Regression: `call` ended with a bare `scope`, discarding the return value
    # of opened_on_weekends and silently disabling the Open Weekends filter.
    it "applies the open_weekends filter" do
      weekend = create(:location, :with_office_hours)
      location_for # a location with no weekend hours

      expect(described_class.call({open_weekends: true}, Location.active).ids)
        .to eq(described_class.opened_on_weekends(Location.active, true).ids)
      expect(described_class.call({open_weekends: true}, Location.active).ids)
        .to include(weekend.id)
    end

    it "applies the give filter" do
      donation = location_for(donation_link: "https://example.org/donate")
      location_for

      expect(described_class.call({give: [Search::GIVE_DONATION]}, Location.active).ids)
        .to contain_exactly(donation.id)
    end
  end

  describe ".by_beneficiary_groups_served" do
    let(:group) { create(:beneficiary_group, name: "Youth") }
    let(:subcategory) { create(:beneficiary_subcategory, name: "Teens", beneficiary_group: group) }
    let!(:location) do
      organization = create(:organization, name: "beneficiary org")
      organization.beneficiary_subcategories << subcategory
      organization.locations.first
    end

    it "matches on a group and subcategory pair" do
      expect(described_class.by_beneficiary_groups_served(Location.active, {"Youth" => ["Teens"]}).ids)
        .to contain_exactly(location.id)
    end

    # Regression: the subcategory value was interpolated into raw SQL, so a
    # quote in a user-supplied filter broke out of the string literal.
    it "binds values containing quotes instead of interpolating them" do
      expect {
        described_class.by_beneficiary_groups_served(Location.active, {"Youth" => ["it's"]}).ids
      }.not_to raise_error

      expect(described_class.by_beneficiary_groups_served(Location.active, {"Youth" => ["it's"]}).ids)
        .to be_empty
    end
  end

  describe ".by_service" do
    let(:cause) { create(:cause, name: "Education") }
    let(:service) { create(:service, name: "Tutoring", cause: cause) }
    let!(:location) do
      location = create(:organization, name: "service org").locations.first
      location.services << service
      location
    end

    it "matches on a cause and service pair" do
      expect(described_class.by_service(Location.active, {"Education" => ["Tutoring"]}).ids)
        .to contain_exactly(location.id)
    end

    it "binds values containing quotes instead of interpolating them" do
      expect {
        described_class.by_service(Location.active, {"Education" => ["it's"]}).ids
      }.not_to raise_error
    end
  end
end
