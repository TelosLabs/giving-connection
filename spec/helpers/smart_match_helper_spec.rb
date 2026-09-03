# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatchHelper, type: :helper do
  let(:section_map) do
    {
      1 => {number: 1, name: "About You"},
      2 => {number: 1, name: "About You"},
      3 => {number: 2, name: "Type of Support"},
      4 => {number: 2, name: "Type of Support"},
      5 => {number: 3, name: "Location"},
      6 => {number: 4, name: "Preferences"}
    }
  end

  describe "#segment_fill_pct" do
    it "returns 0 for a future section" do
      section_steps = [5, 6]
      expect(helper.segment_fill_pct(section_steps, 4, 2, 3)).to eq(0)
    end

    it "returns 100 for a completed section" do
      section_steps = [1, 2]
      expect(helper.segment_fill_pct(section_steps, 1, 3, 5)).to eq(100)
    end

    it "returns partial fill for the current section" do
      section_steps = [3, 4]
      # on step 3 of 2-step section 2 → 1 of 2 steps complete = 50%
      expect(helper.segment_fill_pct(section_steps, 2, 2, 3)).to eq(50)
    end

    it "returns 100% fill when all steps in current section are done" do
      section_steps = [3, 4]
      expect(helper.segment_fill_pct(section_steps, 2, 2, 4)).to eq(100)
    end

    it "returns 0 for an empty section" do
      expect(helper.segment_fill_pct([], 3, 2, 5)).to eq(0)
    end
  end

  describe "#segment_prev_fill_pct" do
    it "returns same as fill_pct for non-current segments" do
      section_steps = [1, 2]
      fill = helper.segment_fill_pct(section_steps, 1, 3, 5)
      expect(helper.segment_prev_fill_pct(section_steps, 1, 3, 5)).to eq(fill)
    end

    it "returns the fill before the current step for the current segment" do
      section_steps = [3, 4]
      # on step 4 → prev fill = steps < 4 in section = [3] = 1/2 = 50%
      expect(helper.segment_prev_fill_pct(section_steps, 2, 2, 4)).to eq(50)
    end

    it "returns 0 as prev fill for the first step of a section" do
      section_steps = [3, 4]
      # on step 3 → prev fill = steps < 3 in section = [] = 0/2 = 0%
      expect(helper.segment_prev_fill_pct(section_steps, 2, 2, 3)).to eq(0)
    end
  end
end
