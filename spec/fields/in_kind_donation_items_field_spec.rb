# frozen_string_literal: true

require "rails_helper"

RSpec.describe InKindDonationItemsField do
  subject(:field) { described_class.new(:in_kind_donation_items, data, :form) }

  let(:data) { ["diapers", "school_supplies"] }

  it "permits the attribute as an array so the dashboard collects it" do
    expect(described_class.permitted_attribute(:in_kind_donation_items))
      .to eq({in_kind_donation_items: []})
  end

  it "exposes the item groups without shadowing Field::Base#options" do
    expect(field.item_groups).to eq(Organizations::Constants::IN_KIND_DONATION_ITEMS)
    expect(field.options).to eq({})
  end

  it "keeps with_options config reachable" do
    configured = described_class.with_options(hint: "pick some")

    expect(configured.new(:in_kind_donation_items, data, :form).options).to eq({hint: "pick some"})
  end

  it "labels the selected items" do
    expect(field.selected_labels).to eq(["Diapers (baby & adult)", "School supplies"])
    expect(field.to_s).to eq("Diapers (baby & adult), School supplies")
  end

  context "when nothing is selected" do
    let(:data) { nil }

    it "has no selected items" do
      expect(field.selected_items).to eq([])
      expect(field.to_s).to eq("")
    end
  end

  context "when a stored key has since been retired" do
    let(:data) { ["diapers", "retired_key"] }

    it "labels only the keys it still knows" do
      expect(field.selected_labels).to eq(["Diapers (baby & adult)"])
    end
  end
end
