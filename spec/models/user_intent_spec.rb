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

  describe ".from_session" do
    let(:session_answers) do
      {
        state: "TN",
        city: "Nashville",
        travel_bucket: "moderate",
        causes: ["Education", "Health"],
        prefs: ["weekend availability"],
        language_input: "I want to help"
      }
    end

    it "returns a UserIntent" do
      expect(described_class.from_session(session_answers: session_answers, user_type: "volunteer")).to be_a(UserIntent)
    end

    it "sets user_type from parameter" do
      result = described_class.from_session(session_answers: session_answers, user_type: "donor")
      expect(result.user_type).to eq("donor")
    end

    it "sets location fields" do
      result = described_class.from_session(session_answers: session_answers, user_type: "volunteer")
      expect(result.state).to eq("TN")
      expect(result.city).to eq("Nashville")
      expect(result.travel_bucket).to eq("moderate")
    end

    it "parses causes into array" do
      result = described_class.from_session(session_answers: session_answers, user_type: "volunteer")
      expect(result.causes_selected).to eq(["Education", "Health"])
    end

    it "parses prefs into array" do
      result = described_class.from_session(session_answers: session_answers, user_type: "volunteer")
      expect(result.prefs_selected).to eq(["weekend availability"])
    end

    it "sets language_input" do
      result = described_class.from_session(session_answers: session_answers, user_type: "volunteer")
      expect(result.language_input).to eq("I want to help")
    end

    it "handles missing causes gracefully" do
      result = described_class.from_session(session_answers: session_answers.except(:causes), user_type: "volunteer")
      expect(result.causes_selected).to eq([])
    end

    it "handles string keys in session answers" do
      result = described_class.from_session(session_answers: session_answers.stringify_keys, user_type: "volunteer")
      expect(result.state).to eq("TN")
    end

    it "strips whitespace and rejects blank causes" do
      answers = session_answers.merge(causes: [" Education ", "", "  ", " Health "])
      result = described_class.from_session(session_answers: answers, user_type: "volunteer")
      expect(result.causes_selected).to eq(["Education", "Health"])
    end
  end

  describe "#to_embedding_text" do
    it "weights causes (cause name appears at least PRIMARY_CAUSE_WEIGHT times)" do
      intent = described_class.new(user_type: "volunteer", state: "TN", city: "Nashville",
        causes_selected: ["Education"])
      expect(intent.to_embedding_text.scan("Education").count).to be >= UserIntent::PRIMARY_CAUSE_WEIGHT
    end

    it "expands causes with synonyms from matching_rules.yml" do
      intent = described_class.new(user_type: "volunteer", state: "TN",
        causes_selected: ["Education"])
      expect(intent.to_embedding_text).to include("tutoring").or include("literacy").or include("schools")
    end

    it "includes location text" do
      intent = described_class.new(user_type: "volunteer", state: "TN", city: "Nashville",
        causes_selected: ["Education"])
      expect(intent.to_embedding_text).to include("Nashville, TN")
    end

    it "includes prefs" do
      intent = described_class.new(user_type: "volunteer", state: "TN",
        causes_selected: ["Education"], prefs_selected: ["weekend availability"])
      expect(intent.to_embedding_text).to include("weekend availability")
    end

    it "places language_input at the front, before structured parts" do
      intent = described_class.new(user_type: "volunteer", state: "TN", city: "Nashville",
        causes_selected: ["Education"], language_input: "FREETEXT_SENTINEL")
      text = intent.to_embedding_text
      expect(text.index("FREETEXT_SENTINEL")).to be < text.index("Education")
    end

    it "caps total length at EMBEDDING_TEXT_MAX_LENGTH" do
      intent = described_class.new(user_type: "service_seeker", state: "TN",
        causes_selected: %w[Education Health Employment Environment Animals] * 10)
      expect(intent.to_embedding_text.length).to be <= UserIntent::EMBEDDING_TEXT_MAX_LENGTH
    end

    it "caps language_input at EMBEDDING_LANGUAGE_INPUT_BUDGET" do
      huge_text = "x" * 5000
      intent = described_class.new(user_type: "volunteer", state: "TN",
        causes_selected: ["Education"], language_input: huge_text)
      text = intent.to_embedding_text
      # the leading free-text run length must not exceed the budget
      free_text_segment = text.split(" | ").first
      expect(free_text_segment.length).to be <= UserIntent::EMBEDDING_LANGUAGE_INPUT_BUDGET
    end
  end
end
