# frozen_string_literal: true

require "rails_helper"

# The results page's optional "looking for a specific service?" refinement.
#
# It replaced a quiz question that asked the same thing before showing any
# results, which overwhelmed people who don't know the service vocabulary. The
# two properties that make the new version safe to ignore AND safe to use:
# nothing it does touches scoring, and no option it offers can empty the page.
RSpec.describe SmartMatch::ServiceFilter do
  let(:submission) { create(:quiz_submission, user_type: "service_seeker") }

  # An organization whose (single) location offers `service_names`, matched to
  # the submission at the given rank.
  def match_offering(*service_names, rank:, cause: "Housing & Homelessness", name: nil)
    organization = create(:organization, name: name || "Org #{rank}", ein_number: "12-000000#{rank}")
    location = organization.locations.first || create(:location, organization: organization)
    location.services = service_names.map { |service| service_named(service, cause) }

    create(:organization_match, quiz_submission: submission, organization: organization,
      score: 1.0 - (rank / 100.0), rank: rank)
  end

  def service_named(name, cause_name)
    Service.find_or_create_by!(name: name) do |service|
      service.cause = Cause.find_or_create_by!(name: cause_name)
    end
  end

  def filter_for(requested = nil)
    described_class.new(pool: submission.organization_matches, requested: requested)
  end

  describe "the options on offer" do
    it "lists only services the matched organizations actually offer" do
      match_offering("Homeless Shelters", rank: 1)
      match_offering("Housing Support Services", rank: 2)
      # Offered by an organization that is NOT a match for this submission.
      other = create(:organization, name: "Unmatched", ein_number: "12-9999999")
      other.locations.first.services = [service_named("Rental Assistance", "Housing & Homelessness")]

      names = filter_for.options.values.flatten.map(&:name)

      expect(names).to contain_exactly("Homeless Shelters", "Housing Support Services")
    end

    it "counts how many matches offer each service" do
      match_offering("Homeless Shelters", rank: 1)
      match_offering("Homeless Shelters", "Housing Support Services", rank: 2)

      counts = filter_for.options.values.flatten.to_h { |option| [option.name, option.count] }

      expect(counts).to eq("Homeless Shelters" => 2, "Housing Support Services" => 1)
    end

    # A service tagged on three of an organization's locations is still one
    # organization; the count promises how many CARDS survive a click.
    it "counts an organization once however many of its locations offer a service" do
      match = match_offering("Homeless Shelters", rank: 1)
      second = create(:location, :with_office_hours, organization: match.organization, main: false)
      second.services = [service_named("Homeless Shelters", "Housing & Homelessness")]

      expect(filter_for.options.values.flatten.first.count).to eq(1)
    end

    it "groups services under their cause" do
      match_offering("Homeless Shelters", cause: "Housing & Homelessness", rank: 1)
      match_offering("Job Training", cause: "Employment", rank: 2)

      expect(filter_for.options.keys).to contain_exactly("Housing & Homelessness", "Employment")
    end

    it "puts the commonest services first within a cause" do
      match_offering("Homeless Shelters", "Housing Support Services", rank: 1)
      match_offering("Housing Support Services", rank: 2)
      match_offering("Housing Support Services", rank: 3)

      names = filter_for.options["Housing & Homelessness"].map(&:name)

      expect(names).to eq(["Housing Support Services", "Homeless Shelters"])
    end

    # The control is a refinement. With one option the only thing it can do is
    # narrow the page to itself, which is not a choice worth rendering.
    it "is unavailable when there is nothing to choose between" do
      match_offering("Homeless Shelters", rank: 1)
      expect(filter_for).not_to be_available

      match_offering("Housing Support Services", rank: 2)
      expect(filter_for).to be_available
    end
  end

  describe "applying a selection" do
    before do
      match_offering("Homeless Shelters", rank: 1, name: "Shelter Org")
      match_offering("Housing Support Services", rank: 2, name: "Support Org")
      match_offering("Homeless Shelters", "Housing Support Services", rank: 3, name: "Both Org")
    end

    def matched_names(filter)
      filter.matches.map { |match| match.organization.name }
    end

    it "returns the whole pool when nothing is selected" do
      filter = filter_for

      expect(filter).not_to be_active
      expect(matched_names(filter)).to contain_exactly("Shelter Org", "Support Org", "Both Org")
    end

    it "keeps only organizations offering the selected service" do
      filter = filter_for(["Homeless Shelters"])

      expect(filter).to be_active
      expect(matched_names(filter)).to contain_exactly("Shelter Org", "Both Org")
    end

    # OR, not AND: two selections mean "either of these would help me", which is
    # what a user ticking two boxes means and what keeps the page non-empty.
    it "keeps organizations offering ANY of several selected services" do
      filter = filter_for(["Homeless Shelters", "Housing Support Services"])

      expect(matched_names(filter)).to contain_exactly("Shelter Org", "Support Org", "Both Org")
    end
  end

  describe "input the user did not give us" do
    before do
      match_offering("Homeless Shelters", rank: 1, name: "Shelter Org")
      match_offering("Housing Support Services", rank: 2, name: "Support Org")
    end

    # A hand-edited or stale URL must degrade to showing MORE, never to an empty
    # page: unknown names are dropped rather than filtered on.
    it "ignores services no match offers" do
      filter = filter_for(["Homeless Shelters", "Underwater Basket Weaving"])

      expect(filter.selected).to eq(["Homeless Shelters"])
      expect(filter.matches.count).to eq(1)
    end

    it "falls back to the whole pool when nothing requested is real" do
      filter = filter_for(["Underwater Basket Weaving"])

      expect(filter).not_to be_active
      expect(filter.matches.count).to eq(2)
    end

    it "tolerates blanks, duplicates and stray whitespace" do
      filter = filter_for(["", "  Homeless Shelters  ", "Homeless Shelters", nil])

      expect(filter.selected).to eq(["Homeless Shelters"])
    end

    it "tolerates a scalar instead of a list" do
      expect(filter_for("Homeless Shelters").selected).to eq(["Homeless Shelters"])
    end
  end
end
