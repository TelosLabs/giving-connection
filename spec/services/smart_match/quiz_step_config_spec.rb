# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::QuizStepConfig do
  describe ".section_map_for" do
    # Counts come from QuizNavigator rather than being repeated here -- the
    # quiz schema consistency spec is what asserts the two agree, so inserting
    # a step does not need an edit in this file.
    %w[service_seeker volunteer donor].each do |user_type|
      it "returns a contiguous map for #{user_type}" do
        map = described_class.section_map_for(user_type)
        total = SmartMatch::QuizNavigator.total_steps_for(user_type)

        expect(map.keys).to eq((1..total).to_a)
      end
    end

    it "falls back to donor map for unknown user type" do
      expect(described_class.section_map_for("unknown")).to eq(described_class.section_map_for("donor"))
    end
  end

  describe ".section_for" do
    it "returns section metadata with number, name, title, and subtitle" do
      info = described_class.section_for("donor", 1)
      expect(info).to include(:number, :name, :title, :subtitle)
    end

    it "returns section 1 data for step 1 across all user types" do
      %w[service_seeker volunteer donor].each do |type|
        info = described_class.section_for(type, 1)
        expect(info[:number]).to eq(1)
        expect(info[:name]).to eq("About You")
      end
    end

    it "returns the first step data as fallback for unknown step" do
      fallback = described_class.section_for("donor", 99)
      expect(fallback).to eq(described_class.section_for("donor", 1))
    end
  end

  describe ".partial_for" do
    it "returns the user_type partial path for user_type step (step 1)" do
      expect(described_class.partial_for("volunteer", 1)).to eq("smart_match/quizzes/steps/user_type")
      expect(described_class.partial_for("donor", 1)).to eq("smart_match/quizzes/steps/user_type")
    end

    it "returns different partials for different user types on the same step" do
      volunteer_partial = described_class.partial_for("volunteer", 4)
      donor_partial = described_class.partial_for("donor", 4)
      expect(volunteer_partial).not_to eq(donor_partial)
    end

    it "returns the location_detail partial right after each flow's city_selection step" do
      SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP.each do |user_type, step|
        expect(described_class.partial_for(user_type, step)).to eq("smart_match/quizzes/steps/location_detail")
      end
    end

    it "returns the final (personal details) partial one step before the end" do
      %w[service_seeker volunteer donor].each do |user_type|
        penultimate = SmartMatch::QuizNavigator.total_steps_for(user_type) - 1
        expect(described_class.partial_for(user_type, penultimate))
          .to eq("smart_match/quizzes/steps/final")
      end
    end

    it "returns the open_text partial for the last step of each user type" do
      %w[service_seeker volunteer donor].each do |user_type|
        last = SmartMatch::QuizNavigator.total_steps_for(user_type)
        expect(described_class.partial_for(user_type, last))
          .to eq("smart_match/quizzes/steps/open_text")
      end
    end

    it "puts the services step right after each flow's cause step" do
      SmartMatch::QuizNavigator::SERVICES_STEP.each do |user_type, step|
        expect(described_class.partial_for(user_type, step)).to eq("smart_match/quizzes/steps/services")
        expect(described_class.partial_for(user_type, step - 1)).to eq("smart_match/quizzes/steps/causes")
      end
    end

    it "falls back to donor partial for unknown user type" do
      expect(described_class.partial_for("unknown", 3)).to eq(described_class.partial_for("donor", 3))
    end
  end
end
