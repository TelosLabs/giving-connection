# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizSubmission, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:organization_matches).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:session_id) }
    it { is_expected.to validate_presence_of(:user_type) }
    it { is_expected.to validate_presence_of(:embedding) }
    it { is_expected.to validate_presence_of(:text_snapshot) }
  end

  describe "JSONB answers" do
    it "stores and retrieves answers hash" do
      submission = create(:quiz_submission, answers: {state: "TN", causes: ["Education"]})

      expect(submission.reload.answers).to include("state" => "TN")
      expect(submission.answers["causes"]).to eq(["Education"])
    end
  end
end
