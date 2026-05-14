# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::SubmissionProcessor do
  let(:vector) { Array.new(1024) { rand(-1.0..1.0) } }
  let(:session_answers) do
    {
      state: "TN",
      city: "Nashville",
      travel_bucket: "moderate",
      causes: ["Education"],
      language_input: "I want to help"
    }
  end

  before do
    allow(SmartMatch::EmbeddingClient).to receive(:call).and_return(vector)
  end

  describe ".call" do
    it "creates a QuizSubmission" do
      org = create(:organization)
      create(:organization_embedding, organization: org)

      expect {
        described_class.call(
          session_answers: session_answers,
          user_type: "volunteer",
          session_id: "test-session"
        )
      }.to change(QuizSubmission, :count).by(1)
    end

    it "creates OrganizationMatch records" do
      org = create(:organization)
      create(:organization_embedding, organization: org)

      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return([
        {
          organization_embedding: OrganizationEmbedding.last,
          cosine_distance: 0.2,
          distance_miles: 5
        }
      ])

      result = described_class.call(
        session_answers: session_answers,
        user_type: "volunteer",
        session_id: "test-session"
      )

      expect(result[:submission].organization_matches.count).to eq(1)
    end

    it "returns submission and ranked results" do
      org = create(:organization)
      create(:organization_embedding, organization: org)

      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return([
        {
          organization_embedding: OrganizationEmbedding.last,
          cosine_distance: 0.2,
          distance_miles: 5
        }
      ])

      result = described_class.call(
        session_answers: session_answers,
        user_type: "volunteer",
        session_id: "test-session"
      )

      expect(result[:submission]).to be_a(QuizSubmission)
      expect(result[:results]).to be_an(Array)
      expect(result[:results].first).to include(:organization, :score, :score_breakdown)
    end

    it "accepts optional user parameter" do
      user = create(:user)
      org = create(:organization)
      create(:organization_embedding, organization: org)

      allow(SmartMatch::SimilarityQuery).to receive(:call).and_return([])

      result = described_class.call(
        session_answers: session_answers,
        user_type: "volunteer",
        session_id: "test-session",
        user: user
      )

      expect(result[:submission].user).to eq(user)
    end
  end
end
