# frozen_string_literal: true

require "rails_helper"

# The self-service edit form is the only route by which Smart Match capability
# data ever arrives -- there is no backfill campaign
# (docs/smart-match-scoring/06-phase-5-fields.md), so organizations filling in
# their own profile is the entire data strategy.
#
# The behaviour these specs protect is the tri-state one. Every capability
# column is nullable because RuleScorer treats NULL as "nobody has told us" and
# skips the rule, while `false` is a recorded "no" that counts against the
# organization. A form that could only express true/false would silently record
# a definite "no" for every field an organization never touched.
RSpec.describe "Organization Smart Match fields", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    create(:organization_admin, organization: organization, user: user)
    sign_in user
  end

  def update_organization(attrs)
    patch organization_path(organization), params: {organization: attrs}
    organization.reload
  end

  describe "the edit form" do
    it "renders the Smart Match section" do
      get edit_organization_path(organization)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Smart Match Details")
      expect(response.body).to include("Do you offer free or sliding-scale services?")
      expect(response.body).to include("Which languages can you deliver services in?")
      expect(response.body).to include("Is this location wheelchair accessible?")
    end

    it "offers a Not specified option for every boolean capability" do
      get edit_organization_path(organization)

      expect(response.body.scan("Not specified").size).to be >= 8
    end
  end

  describe "saving capabilities" do
    it "stores an explicit yes" do
      update_organization(free_or_sliding_scale: "true", accepts_in_kind: "true")

      expect(organization.free_or_sliding_scale).to be(true)
      expect(organization.accepts_in_kind).to be(true)
    end

    it "stores an explicit no" do
      update_organization(no_id_required: "false")

      expect(organization.no_id_required).to be(false)
    end

    # The load-bearing case: "Not specified" must come back as NULL, not false.
    it "stores Not specified as nil rather than false" do
      organization.update_columns(lgbtqia_affirming: true)

      update_organization(lgbtqia_affirming: "")

      expect(organization.lgbtqia_affirming).to be_nil
    end

    it "leaves untouched capabilities nil" do
      update_organization(free_or_sliding_scale: "true")

      expect(organization.recurring_giving).to be_nil
      expect(organization.fundraising_events).to be_nil
    end
  end

  describe "saving vocabularies" do
    it "stores selected languages" do
      update_organization(languages: ["English", "Spanish"])

      expect(organization.languages).to contain_exactly("English", "Spanish")
    end

    it "stores volunteer format, frequency and leadership attributes" do
      update_organization(
        volunteer_format: "Hybrid",
        volunteer_frequency: ["Weekly", "Ongoing"],
        leadership_attributes: ["Women-led"]
      )

      expect(organization.volunteer_format).to eq("Hybrid")
      expect(organization.volunteer_frequency).to contain_exactly("Weekly", "Ongoing")
      expect(organization.leadership_attributes).to contain_exactly("Women-led")
    end

    it "rejects a value outside the vocabulary" do
      update_organization(leadership_attributes: ["Alien-led"])

      expect(organization.leadership_attributes).to be_nil
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "saving location-level capabilities" do
    it "stores wheelchair access and remote services per location" do
      location = organization.locations.first

      update_organization(
        locations_attributes: {
          "0" => {id: location.id, wheelchair_accessible: "true", remote_services: "false"}
        }
      )

      expect(location.reload.wheelchair_accessible).to be(true)
      expect(location.remote_services).to be(false)
    end

    it "stores Not specified on a location as nil" do
      location = organization.locations.first
      location.update_columns(wheelchair_accessible: true)

      update_organization(
        locations_attributes: {"0" => {id: location.id, wheelchair_accessible: ""}}
      )

      expect(location.reload.wheelchair_accessible).to be_nil
    end
  end
end
