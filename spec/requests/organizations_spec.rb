# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  before do
    create(:organization_admin, organization: organization, user: user)
    sign_in user
  end

  def patch_organization(attributes)
    patch organization_path(organization), params: {organization: {tags_attributes: ""}.merge(attributes)}
  end

  describe "PATCH /organizations/:id" do
    it "stores the submitted in-kind donation items" do
      patch_organization(in_kind_donation_items: ["", "diapers", "diapers"])

      expect(organization.reload.in_kind_donation_items).to eq(["diapers"])
    end

    it "clears the list when only the blank sentinel is submitted" do
      organization.update!(in_kind_donation_items: ["diapers"])

      patch_organization(in_kind_donation_items: [""])

      expect(organization.reload.in_kind_donation_items).to eq([])
    end

    it "ignores in-kind donation items sent as a scalar instead of an array" do
      organization.update!(in_kind_donation_items: ["diapers"])

      patch_organization(in_kind_donation_items: "shoes")

      expect(organization.reload.in_kind_donation_items).to eq(["diapers"])
    end

    it "does not let an unsupported item through" do
      patch_organization(in_kind_donation_items: ["not-supported"])

      expect(response).to have_http_status(:unprocessable_entity)
      expect(organization.reload.in_kind_donation_items).to eq([])
    end

    it "strips unpermitted attributes" do
      other_admin = create(:admin_user)

      patch_organization(in_kind_donation_items: ["diapers"], creator_id: other_admin.id)

      expect(organization.reload.creator_id).not_to eq(other_admin.id)
    end

    it "stores the in-kind donation link" do
      patch_organization(in_kind_donation_link: "https://example.org/wishlist")

      expect(organization.reload.in_kind_donation_link).to eq("https://example.org/wishlist")
    end

    it "rejects an in-kind donation link that is not http(s)" do
      patch_organization(in_kind_donation_link: "javascript:alert(1)")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(organization.reload.in_kind_donation_link).to be_nil
    end
  end
end
