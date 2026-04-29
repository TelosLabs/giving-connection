# frozen_string_literal: true

FactoryBot.define do
  factory :organization_match do
    quiz_submission
    organization
    score { 0.85 }
    rank { 1 }
    score_breakdown do
      {
        dense_similarity: 0.90,
        attribute_bonus: 0.75,
        distance_score: 0.80
      }
    end
  end
end
