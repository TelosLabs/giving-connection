# frozen_string_literal: true

require "rails_helper"

RSpec.describe SelectMultiple::Component do
  describe "#checked?" do
    it "renders the current selection for the form variant" do
      component = described_class.new(name: "organization[in_kind_donation_items]",
        items: Organization.in_kind_donation_items_options, selected: ["diapers"])

      expect(component.checked?("diapers")).to be(true)
      expect(component.checked?("shoes")).to be(false)
    end

    # The advanced-search filters hydrate from filterStore in JS and compare
    # against defaultChecked, so they must keep rendering unchecked.
    it "never renders a checked box for the search variant" do
      component = described_class.new(name: "search[causes]", items: ["Housing"],
        selected: ["Housing"], stimulus_controller: "select-multiple-search")

      expect(component.checked?("Housing")).to be(false)
    end

    it "handles a nil selection" do
      component = described_class.new(name: "search[causes]", items: ["Housing"], selected: nil)

      expect(component.checked?("Housing")).to be(false)
    end
  end

  describe "#options" do
    it "wires the clear action to the component's own stimulus controller" do
      component = described_class.new(name: "search[causes]", items: ["Housing"],
        stimulus_controller: "select-multiple-search")

      expect(component.options[:data][:action])
        .to include("selectmultiple:clear->select-multiple-search#clearAll")
    end
  end
end
