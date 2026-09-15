# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrganizationDecorator do
  let(:organization) { create(:organization) }

  describe "#in_kind_donation_items" do
    it "maps stored keys to their labels" do
      organization.update!(in_kind_donation_items: ["diapers", "school_supplies"])

      expect(organization.decorate.in_kind_donation_items)
        .to eq(["Diapers (baby & adult)", "School supplies"])
    end

    it "drops keys that are no longer part of the item list" do
      organization.update_column(:in_kind_donation_items, ["diapers", "retired_key"])

      expect(organization.reload.decorate.in_kind_donation_items).to eq(["Diapers (baby & adult)"])
    end

    it "is empty when nothing is selected" do
      expect(organization.decorate.in_kind_donation_items).to eq([])
    end
  end

  describe "#in_kind_donation_link" do
    it "returns http(s) links untouched" do
      organization.update!(in_kind_donation_link: "https://example.org/wishlist")

      expect(organization.decorate.in_kind_donation_link).to eq("https://example.org/wishlist")
    end

    # Validation rejects these now, but rows predating it still have to render safely.
    ["javascript:alert(1)", "example.org/needs", "ftp://example.org/needs"].each do |stored_link|
      it "returns nil for #{stored_link.inspect}" do
        organization.update_column(:in_kind_donation_link, stored_link)

        expect(organization.reload.decorate.in_kind_donation_link).to be_nil
      end
    end

    it "returns nil when unset" do
      expect(organization.decorate.in_kind_donation_link).to be_nil
    end
  end
end
