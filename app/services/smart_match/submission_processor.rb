# frozen_string_literal: true

module SmartMatch
  class SubmissionProcessor < ApplicationService
    attr_reader :session_answers, :user_type, :session_id, :attempt_token, :user

    def initialize(session_answers:, user_type:, session_id:, attempt_token: nil, user: nil)
      @session_answers = session_answers
      @user_type = user_type
      @session_id = session_id
      @attempt_token = attempt_token
      @user = user
    end

    def call
      user_intent = build_user_intent
      quiz_text = user_intent.to_embedding_text
      vector = EmbeddingClient.call(text: quiz_text)

      retrieval = find_candidates(vector, user_intent)
      ranked = Scorer.call(candidates: retrieval.candidates, user_intent: user_intent)

      submission = ActiveRecord::Base.transaction do
        s = create_submission(quiz_text, vector, retrieval.relaxed)
        save_matches(s, ranked)
        s
      end

      {submission: submission, results: ranked, relaxed: retrieval.relaxed}
    end

    private

    def build_user_intent
      UserIntent.from_session(
        session_answers: session_answers,
        user_type: user_type
      )
    end

    def create_submission(text, vector, relaxations)
      QuizSubmission.create!(
        user: user,
        session_id: session_id,
        answers: session_answers,
        user_type: user_type,
        embedding: vector,
        text_snapshot: text,
        search_relaxations: relaxations,
        attempt_token: attempt_token
      )
    end

    def find_candidates(vector, user_intent)
      coordinates = resolve_coordinates(user_intent)
      radius = resolve_radius(user_intent.travel_bucket)

      SimilarityQuery.call(
        embedding: vector,
        state: user_intent.state,
        coordinates: coordinates,
        radius_miles: radius,
        location_scope: user_intent.location_scope,
        user_intent: user_intent
      )
    end

    def save_matches(submission, ranked)
      ranked.each_with_index do |result, index|
        OrganizationMatch.create!(
          quiz_submission: submission,
          organization: result[:organization],
          score: result[:score],
          score_breakdown: result[:score_breakdown],
          rank: index + 1
        )
      end
    end

    # Returns nil when we cannot resolve a city/state to coordinates. Callers
    # (SimilarityQuery, Scorer.distance_score) treat nil coordinates / nil
    # distance as "no distance bonus" rather than substituting a default city.
    def resolve_coordinates(user_intent)
      state_data = SmartMatch::CITY_CENTROIDS[user_intent.state]
      return nil unless state_data

      city_data = state_data[user_intent.city]
      return nil unless city_data

      {latitude: city_data["latitude"], longitude: city_data["longitude"]}
    end

    def resolve_radius(travel_bucket)
      SmartMatch::MATCHING_RULES.dig("radius_by_travel_bucket", travel_bucket) || 5
    end
  end
end
