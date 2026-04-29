# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::QuizStepConfig do
  describe ".section_map_for" do
    it "returns the correct map for service_seeker" do
      map = described_class.section_map_for("service_seeker")
      expect(map.keys).to eq((1..9).to_a)
    end

    it "returns the correct map for volunteer" do
      map = described_class.section_map_for("volunteer")
      expect(map.keys).to eq((1..8).to_a)
    end

    it "returns the correct map for donor" do
      map = described_class.section_map_for("donor")
      expect(map.keys).to eq((1..9).to_a)
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
      volunteer_partial = described_class.partial_for("volunteer", 3)
      donor_partial = described_class.partial_for("donor", 3)
      expect(volunteer_partial).not_to eq(donor_partial)
    end

    it "returns the final partial for last step of volunteer (step 8)" do
      expect(described_class.partial_for("volunteer", 8)).to eq("smart_match/quizzes/steps/final")
    end

    it "returns the final partial for last step of donor (step 9)" do
      expect(described_class.partial_for("donor", 9)).to eq("smart_match/quizzes/steps/final")
    end

    it "falls back to donor partial for unknown user type" do
      expect(described_class.partial_for("unknown", 3)).to eq(described_class.partial_for("donor", 3))
    end
  end
end
