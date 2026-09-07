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

  # attempt_token is ProcessSubmissionJob's idempotency key. The guards that
  # normally enforce it -- an atomic cache claim in the controller, an exists?
  # check in the job -- both live outside Postgres and fail together when the
  # cache store does. The unique index is the guarantee that survives that.
  describe "attempt_token uniqueness" do
    it "refuses a second submission for the same attempt" do
      token = SecureRandom.uuid
      create(:quiz_submission, attempt_token: token)

      expect { create(:quiz_submission, attempt_token: token) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    # Rows predating the column hold NULL, and Postgres treats NULLs in a
    # unique index as distinct -- so the constraint does not retroactively
    # reject them.
    it "allows any number of submissions with no attempt recorded" do
      create(:quiz_submission, attempt_token: nil)

      expect { create(:quiz_submission, attempt_token: nil) }.not_to raise_error
    end
  end
end
