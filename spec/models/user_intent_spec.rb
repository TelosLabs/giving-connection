# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserIntent do
  describe "validations" do
    it "is valid with required attributes" do
      intent = described_class.new(
        user_type: "volunteer",
        state: "TN",
        causes_selected: ["Education"]
      )

      expect(intent).to be_valid
    end

    it "requires user_type" do
      intent = described_class.new(state: "TN", causes_selected: ["Education"])

      expect(intent).not_to be_valid
      expect(intent.errors[:user_type]).to be_present
    end

    it "requires state" do
      intent = described_class.new(user_type: "volunteer", causes_selected: ["Education"])

      expect(intent).not_to be_valid
      expect(intent.errors[:state]).to be_present
    end

    it "requires causes_selected" do
      intent = described_class.new(user_type: "volunteer", state: "TN")

      expect(intent).not_to be_valid
      expect(intent.errors[:causes_selected]).to be_present
    end

    it "validates user_type inclusion" do
      intent = described_class.new(
        user_type: "invalid",
        state: "TN",
        causes_selected: ["Education"]
      )

      expect(intent).not_to be_valid
      expect(intent.errors[:user_type]).to be_present
    end

    %w[service_seeker volunteer donor].each do |type|
      it "accepts #{type} as user_type" do
        intent = described_class.new(
          user_type: type,
          state: "TN",
          causes_selected: ["Education"]
        )

        expect(intent).to be_valid
      end
    end
  end

  describe "optional attributes" do
    it "accepts city" do
      intent = described_class.new(
        user_type: "volunteer",
        state: "TN",
        city: "Nashville",
        causes_selected: ["Education"]
      )

      expect(intent.city).to eq("Nashville")
    end

    it "accepts travel_bucket" do
      intent = described_class.new(
        user_type: "volunteer",
        state: "TN",
        travel_bucket: "moderate",
        causes_selected: ["Education"]
      )

      expect(intent.travel_bucket).to eq("moderate")
    end

    it "accepts language_input" do
      intent = described_class.new(
        user_type: "volunteer",
        state: "TN",
        causes_selected: ["Education"],
        language_input: "I want to help with education"
      )

      expect(intent.language_input).to eq("I want to help with education")
    end

    it "accepts prefs_selected" do
      intent = described_class.new(
        user_type: "volunteer",
        state: "TN",
        causes_selected: ["Education"],
        prefs_selected: ["weekend_availability"]
      )

      expect(intent.prefs_selected).to eq(["weekend_availability"])
    end
  end
end
