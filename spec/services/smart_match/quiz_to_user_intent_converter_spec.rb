# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::QuizToUserIntentConverter do
  describe ".call" do
    let(:session_answers) do
      {
        state: "TN",
        city: "Nashville",
        travel_bucket: "moderate",
        causes: ["Education", "Health"],
        preferences: ["weekend availability"],
        language_input: "I want to help"
      }
    end

    it "returns a UserIntent object" do
      result = described_class.call(session_answers: session_answers, user_type: "volunteer")

      expect(result).to be_a(UserIntent)
    end

    it "sets user_type from parameter" do
      result = described_class.call(session_answers: session_answers, user_type: "donor")

      expect(result.user_type).to eq("donor")
    end

    it "sets location fields" do
      result = described_class.call(session_answers: session_answers, user_type: "volunteer")

      expect(result.state).to eq("TN")
      expect(result.city).to eq("Nashville")
      expect(result.travel_bucket).to eq("moderate")
    end

    it "parses causes into array" do
      result = described_class.call(session_answers: session_answers, user_type: "volunteer")

      expect(result.causes_selected).to eq(["Education", "Health"])
    end

    it "parses preferences into array" do
      result = described_class.call(session_answers: session_answers, user_type: "volunteer")

      expect(result.prefs_selected).to eq(["weekend availability"])
    end

    it "sets language_input" do
      result = described_class.call(session_answers: session_answers, user_type: "volunteer")

      expect(result.language_input).to eq("I want to help")
    end

    it "handles missing causes gracefully" do
      answers = session_answers.except(:causes)
      result = described_class.call(session_answers: answers, user_type: "volunteer")

      expect(result.causes_selected).to eq([])
    end

    it "handles string keys in session answers" do
      string_answers = session_answers.stringify_keys
      result = described_class.call(session_answers: string_answers, user_type: "volunteer")

      expect(result.state).to eq("TN")
    end

    it "strips whitespace from causes" do
      answers = session_answers.merge(causes: [" Education ", " Health "])
      result = described_class.call(session_answers: answers, user_type: "volunteer")

      expect(result.causes_selected).to eq(["Education", "Health"])
    end

    it "rejects blank causes" do
      answers = session_answers.merge(causes: ["Education", "", "  "])
      result = described_class.call(session_answers: answers, user_type: "volunteer")

      expect(result.causes_selected).to eq(["Education"])
    end
  end
end
