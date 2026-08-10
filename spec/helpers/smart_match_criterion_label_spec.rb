# frozen_string_literal: true

require "rails_helper"

# The results panel names every answer the user gave. A question whose locale
# block is named differently from its session key would fall back to a
# humanized token ("Wheelchair accessible" instead of "Wheelchair accessible
# locations"), which is the kind of degradation nothing else would catch.
RSpec.describe SmartMatchHelper, type: :helper do
  describe "#smart_match_criterion_label" do
    it "resolves a label for every scored answer of every enumerated question" do
      questions = SmartMatch::SCORING_RULES.fetch("questions")

      questions.each do |key, question|
        session_key = question["session_key"] || key
        next if described_class::SELF_LABELLING_CRITERIA.include?(session_key)

        question.fetch("answers", {}).each do |answer, entry|
          rules = entry.is_a?(Hash) ? Array(entry["rules"]) : Array(entry)
          # Escape hatches never appear as criteria.
          next if rules.empty? || answer == "*"

          # Assert the key resolves rather than comparing to humanize --
          # some labels legitimately equal their humanized token ("senior").
          step = described_class::CRITERION_LOCALE_KEYS.fetch(session_key, session_key)

          expect(I18n.exists?("smart_match.quiz.steps.#{step}.options.#{answer}")).to be(true),
            "#{session_key}.#{answer} has no locale entry at " \
            "smart_match.quiz.steps.#{step}.options.#{answer} -- add one, or map " \
            "the session key in CRITERION_LOCALE_KEYS"
        end
      end
    end

    it "shows causes and services by their own name" do
      expect(helper.smart_match_criterion_label("causes", "Mental Health")).to eq("Mental Health")
      expect(helper.smart_match_criterion_label("services", "Homeless Shelters")).to eq("Homeless Shelters")
    end

    it "falls back to a readable token for an unknown answer" do
      expect(helper.smart_match_criterion_label("prefs", "brand_new_option")).to eq("Brand new option")
    end
  end
end
