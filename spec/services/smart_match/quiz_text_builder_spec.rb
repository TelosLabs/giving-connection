# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::QuizTextBuilder do
  describe ".call" do
    it "builds text with weighted causes" do
      intent = UserIntent.new(
        user_type: "volunteer",
        state: "TN",
        city: "Nashville",
        causes_selected: ["Education"]
      )

      result = described_class.call(user_intent: intent)

      expect(result.scan("Education").count).to be >= 3
    end

    it "expands causes with synonyms from matching_rules.yml" do
      intent = UserIntent.new(
        user_type: "volunteer",
        state: "TN",
        causes_selected: ["Education"]
      )

      result = described_class.call(user_intent: intent)

      expect(result).to include("tutoring").or include("literacy").or include("schools")
    end

    it "includes location text" do
      intent = UserIntent.new(
        user_type: "volunteer",
        state: "TN",
        city: "Nashville",
        causes_selected: ["Education"]
      )

      result = described_class.call(user_intent: intent)

      expect(result).to include("Nashville, TN")
    end

    it "includes preferences" do
      intent = UserIntent.new(
        user_type: "volunteer",
        state: "TN",
        causes_selected: ["Education"],
        prefs_selected: ["weekend availability"]
      )

      result = described_class.call(user_intent: intent)

      expect(result).to include("weekend availability")
    end

    it "truncates at 1500 characters" do
      intent = UserIntent.new(
        user_type: "service_seeker",
        state: "TN",
        causes_selected: %w[Education Health Employment Environment Animals] * 10
      )

      result = described_class.call(user_intent: intent)

      expect(result.length).to be <= 1500
    end
  end
end
