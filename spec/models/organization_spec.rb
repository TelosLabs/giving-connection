# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations
#
#  id                   :bigint           not null, primary key
#  name                 :string           not null
#  ein_number           :string           not null
#  irs_ntee_code        :string           not null
#  website              :string
#  scope_of_work        :string           not null
#  creator_type         :string
#  creator_id           :bigint
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mission_statement_en :text             not null
#  mission_statement_es :text
#  vision_statement_en  :text             not null
#  vision_statement_es  :text
#  tagline_en           :text             not null
#  tagline_es           :text
#  second_name          :string
#  phone_number         :string
#  email                :string
#
require "rails_helper"

RSpec.describe Organization, type: :model do
  subject { create(:organization) }

  describe "Associations" do
    it { is_expected.to have_many(:tags).dependent(:destroy) }
    it { is_expected.to have_many(:organization_causes).dependent(:destroy) }
    it { is_expected.to have_many(:causes) }
    it { is_expected.to have_many(:organization_beneficiaries).dependent(:destroy) }
    it { is_expected.to have_many(:organization_admins).dependent(:destroy) }
    it { is_expected.to have_many(:beneficiary_subcategories) }
    it { is_expected.to have_many(:locations).dependent(:destroy) }
    it { is_expected.to have_many(:additional_locations).conditions(main: false) }
    it { is_expected.to have_one(:main_location).conditions(main: true) }
    it { is_expected.to have_one(:social_media).dependent(:destroy) }
    it { is_expected.to have_one_attached(:logo) }
    it { is_expected.to have_one_attached(:cover_photo) }
    it { is_expected.to belong_to(:creator) }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:organization_causes) }
    it { is_expected.to validate_presence_of(:ein_number) }
    it { is_expected.to validate_presence_of(:irs_ntee_code) }
    it { is_expected.to validate_inclusion_of(:irs_ntee_code).in_array(Organizations::Constants::NTEE_CODE) }
    it { is_expected.to validate_presence_of(:mission_statement_en) }
    it { is_expected.to validate_presence_of(:scope_of_work) }
    it { is_expected.to validate_inclusion_of(:scope_of_work).in_array(Organizations::Constants::SCOPE) }
  end

  describe "in-kind donation items" do
    it "persists a selected list of approved items" do
      organization = create(:organization, in_kind_donation_items: ["clothing_general", "diapers"])

      expect(organization.in_kind_donation_items).to eq(["clothing_general", "diapers"])
    end

    it "defaults to an empty list" do
      expect(create(:organization).in_kind_donation_items).to eq([])
    end

    it "drops blanks, de-duplicates and coerces to strings" do
      organization = create(:organization, in_kind_donation_items: ["", :diapers, "diapers", nil, "shoes"])

      expect(organization.in_kind_donation_items).to eq(["diapers", "shoes"])
    end

    it "rejects unsupported items" do
      organization = build(:organization, in_kind_donation_items: ["clothing_general", "not-supported"])

      expect(organization).not_to be_valid
      expect(organization.errors[:in_kind_donation_items]).to include("contains unsupported item(s): not-supported")
    end

    it "still saves a record holding an item key that has since been retired" do
      organization = create(:organization)
      organization.update_column(:in_kind_donation_items, ["retired_key"])
      organization.reload

      organization.phone_number = "555-0100"

      expect(organization.save).to be(true)
      expect(organization.reload.in_kind_donation_items).to eq(["retired_key"])
    end
  end

  describe "in-kind donation link" do
    it "persists a link to the org's own in-kind donation needs" do
      organization = create(:organization, in_kind_donation_link: "https://example.org/wishlist")

      expect(organization.in_kind_donation_link).to eq("https://example.org/wishlist")
    end

    ["javascript:alert(1)", "data:text/html,<script>alert(1)</script>", "ftp://example.org/needs",
      "example.org/needs", "not a url"].each do |bad_link|
      it "rejects #{bad_link.inspect}" do
        organization = build(:organization, in_kind_donation_link: bad_link)

        expect(organization).not_to be_valid
        expect(organization.errors[:in_kind_donation_link]).to include("URL incorrect format")
      end
    end

    it "keeps accepting scheme-less values on the legacy link columns" do
      organization = build(:organization, website: "www.example.org", donation_link: "www.example.org/give",
        volunteer_link: "www.example.org/volunteer")

      expect(organization).to be_valid
    end

    it "rejects an unsafe scheme on the legacy link columns" do
      organization = build(:organization, donation_link: "javascript:alert(1)")

      expect(organization).not_to be_valid
      expect(organization.errors[:donation_link]).to include("URL incorrect format")
    end
  end
end
