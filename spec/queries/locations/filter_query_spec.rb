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

    it "never matches organizations offering none of the selected options" do
      ids = described_class.by_give(Location.active, Search::GIVE_OPTIONS.keys).ids

      expect(ids).not_to include(nothing.id)
    end

    it "survives a give value whose in-kind column is not a json array" do
      Organization.where(id: nothing.organization_id)
        .update_all("in_kind_donation_items = '{}'::jsonb") # a json object, not an array

      expect { described_class.by_give(Location.active, [Search::GIVE_IN_KIND]).ids }
        .not_to raise_error
    end
  end

  describe ".give_rank" do
    let!(:donation) { location_for(donation_link: "https://example.org/donate") }
    let!(:volunteer) do
      location_for(volunteer_availability: true, volunteer_link: "https://example.org/volunteer")
    end

    it "ranks locations matching more give pills first" do
      everything = location_for(
        donation_link: "https://example.org/donate",
        volunteer_availability: true,
        volunteer_link: "https://example.org/volunteer"
      )

      ids = Location.joins(:organization)
        .order(described_class.give_rank([Search::GIVE_DONATION, Search::GIVE_VOLUNTEER]), :id)
        .ids

      expect(ids.first).to eq(everything.id)
      expect(ids).to include(donation.id, volunteer.id)
    end

    it "does not grow with the number of matching rows" do
      rank = described_class.give_rank([Search::GIVE_DONATION]).to_s

      5.times { location_for(donation_link: "https://example.org/donate") }

      expect(described_class.give_rank([Search::GIVE_DONATION]).to_s).to eq(rank)
    end

    it "ranks nothing when no give value is recognised" do
      expect(described_class.give_rank(["Nonsense"]).to_s).to eq("0")
      expect(described_class.give_rank(nil).to_s).to eq("0")
    end
  end

  describe ".call" do
    # `call` must return the last filter in the chain. An earlier commit on this
    # branch ended it with a bare `scope`, which dropped opened_on_weekends's
    # return value and silently disabled the Open Weekends filter.
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

    # by_cause and by_service hand back a GROUP BY relation, so give has to
    # compose with one rather than with a plain Location scope.
    # Cause and Service both validate global name uniqueness, and CI seeds the
    # test database (db:prepare runs populate:seed_causes_and_services), so a
    # real cause name like "Education" is already taken there. Use names the
    # seed list will never contain.
    it "composes give with a cause filter" do
      cause = create(:cause, name: "Give Filter Cause")
      matching = location_for(donation_link: "https://example.org/donate")
      matching.organization.causes << cause
      other = location_for
      other.organization.causes << cause
      location_for(donation_link: "https://example.org/donate") # right give, wrong cause

      ids = described_class.call(
        {causes: [cause.name], give: [Search::GIVE_DONATION]}, Location.active
      ).ids

      expect(ids).to contain_exactly(matching.id)
    end

    it "composes give with a service filter" do
      cause = create(:cause, name: "Give Filter Cause")
      service = create(:service, name: "Give Filter Service", cause: cause)
      matching = location_for(donation_link: "https://example.org/donate")
      matching.services << service
      other = location_for
      other.services << service

      ids = described_class.call(
        {services: {cause.name => [service.name]}, give: [Search::GIVE_DONATION]}, Location.active
      ).ids

      expect(ids).to contain_exactly(matching.id)
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

    # Regression: the subcategory value was interpolated into raw SQL with no
    # escaping at all, so a quote in search[beneficiary_groups][<group>][] closed
    # the string literal and the rest of the value was executed as SQL. The
    # search page is reachable unauthenticated.
    it "binds a subcategory that closes the IN list instead of executing it" do
      injected = {"Youth" => ["x') OR 1=1) --"]}

      expect { described_class.by_beneficiary_groups_served(Location.active, injected).ids }
        .not_to raise_error
      expect(described_class.by_beneficiary_groups_served(Location.active, injected).ids).to be_empty
    end

    # The same hole, weaponised without a syntax error: the payload closes the
    # tuple and appends one of its own, so the query matched a subcategory the
    # request never asked for. Verified against main: this returned the Teens
    # location; with bound values it returns nothing.
    it "cannot widen the IN list to match rows the filter did not ask for" do
      payload = {"Youth" => ["x'),('Youth','Teens"]}

      expect(described_class.by_beneficiary_groups_served(Location.active, payload).ids)
        .to be_empty
    end

    it "binds a subcategory containing a quote" do
      expect(described_class.by_beneficiary_groups_served(Location.active, {"Youth" => ["it's"]}).ids)
        .to be_empty
    end

    it "matches nothing when a group is present with no subcategories" do
      expect(described_class.by_beneficiary_groups_served(Location.active, {"Youth" => []}).ids)
        .to be_empty
    end

    # The group key was escaped on main, unlike the subcategory value, so this
    # was never the hole. It is bound now like everything else, and this pins
    # that so a future edit cannot quietly drop the key back into raw SQL.
    it "binds a group key that closes the IN list instead of executing it" do
      injected = {"x') OR 1=1) --" => ["Teens"]}

      expect { described_class.by_beneficiary_groups_served(Location.active, injected).ids }
        .not_to raise_error
      expect(described_class.by_beneficiary_groups_served(Location.active, injected).ids).to be_empty
    end

    # Rack param nesting can deliver a subcategory as an array rather than a
    # string. Coercing to a scalar keeps the bind count matched to the
    # placeholders instead of raising on the unauthenticated search endpoint.
    it "does not raise when a subcategory value is a nested array" do
      malformed = {"Youth" => [["a", "b"]]}

      expect { described_class.by_beneficiary_groups_served(Location.active, malformed).ids }
        .not_to raise_error
      expect(described_class.by_beneficiary_groups_served(Location.active, malformed).ids).to be_empty
    end
  end

  describe ".by_service" do
    # Cause and Service both validate global name uniqueness, and CI seeds the
    # test database (db:prepare runs populate:seed_causes_and_services), so a
    # real cause name like "Education" is already taken there. Use names the
    # seed list will never contain.
    let(:cause) { create(:cause, name: "Filter Spec Cause") }
    let(:service) { create(:service, name: "Filter Spec Service", cause: cause) }
    let!(:location) do
      location = create(:organization, name: "service org").locations.first
      location.services << service
      location
    end

    it "matches on a cause and service pair" do
      expect(described_class.by_service(Location.active, {cause.name => [service.name]}).ids)
        .to contain_exactly(location.id)
    end

    # Unlike by_beneficiary_groups_served, by_service already doubled quotes on
    # both values on main, so these payloads never escaped the literal. These
    # tests pin the bound behavior and guard against a regression to raw
    # interpolation.
    it "binds a service that closes the IN list instead of executing it" do
      injected = {cause.name => ["x') OR 1=1) --"]}

      expect { described_class.by_service(Location.active, injected).ids }.not_to raise_error
      expect(described_class.by_service(Location.active, injected).ids).to be_empty
    end

    it "matches nothing when a cause is present with no services" do
      expect(described_class.by_service(Location.active, {cause.name => []}).ids).to be_empty
    end
  end
end
