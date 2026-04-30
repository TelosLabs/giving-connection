# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::OrganizationTextBuilder do
  describe ".call" do
    it "builds text from organization fields" do
      org = create(:organization,
        name: "Test Nonprofit",
        mission_statement_en: "Help people",
        vision_statement_en: "A better world",
        tagline_en: "Making change")

      result = described_class.call(organization: org)

      expect(result).to include("Test Nonprofit")
      expect(result).to include("Help people")
      expect(result).to include("A better world")
      expect(result).to include("Making change")
    end

    it "includes cause names" do
      org = create(:organization)

      result = described_class.call(organization: org)

      org.causes.each do |cause|
        expect(result).to include(cause.name)
      end
    end

    it "truncates text at 1500 characters" do
      org = create(:organization,
        mission_statement_en: "A" * 2000)

      result = described_class.call(organization: org)

      expect(result.length).to be <= 1500
    end

    it "returns nil when all fields are blank" do
      org = build(:organization,
        name: nil,
        mission_statement_en: nil,
        vision_statement_en: nil,
        tagline_en: nil)
      allow(org).to receive(:causes).and_return(Cause.none)
      allow(org).to receive(:beneficiary_subcategories).and_return(BeneficiarySubcategory.none)
      allow(org).to receive(:main_location).and_return(nil)

      result = described_class.call(organization: org)

      expect(result).to be_nil
    end
  end
end
