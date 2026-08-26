# frozen_string_literal: true

require "rails_helper"

RSpec.describe Locations::FilterQuery do
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

    it "binds a service that closes the IN list instead of executing it" do
      injected = {"Education" => ["x') OR 1=1) --"]}

      expect { described_class.by_service(Location.active, injected).ids }.not_to raise_error
      expect(described_class.by_service(Location.active, injected).ids).to be_empty
    end

    it "matches nothing when a cause is present with no services" do
      expect(described_class.by_service(Location.active, {"Education" => []}).ids).to be_empty
    end
  end
end
