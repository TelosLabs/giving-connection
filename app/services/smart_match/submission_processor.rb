# frozen_string_literal: true

module SmartMatch
  class SubmissionProcessor < ApplicationService
    attr_reader :session_answers, :user_type, :session_id, :user

    def initialize(session_answers:, user_type:, session_id:, user: nil)
      @session_answers = session_answers
      @user_type = user_type
      @session_id = session_id
      @user = user
    end

    def call
      user_intent = build_user_intent
      quiz_text = QuizTextBuilder.call(user_intent: user_intent)
      vector = EmbeddingClient.call(text: quiz_text)

      submission = create_submission(quiz_text, vector)
      candidates = find_candidates(vector, user_intent)
      ranked = Scorer.call(candidates: candidates, user_intent: user_intent)

      save_matches(submission, ranked)

      {submission: submission, results: ranked}
    end

    private

    def build_user_intent
      QuizToUserIntentConverter.call(
        session_answers: session_answers,
        user_type: user_type
      )
    end

    def create_submission(text, vector)
      QuizSubmission.create!(
        user: user,
        session_id: session_id,
        answers: session_answers,
        user_type: user_type,
        embedding: vector,
        text_snapshot: text
      )
    end

    def find_candidates(vector, user_intent)
      coordinates = resolve_coordinates(user_intent)
      radius = resolve_radius(user_intent.travel_bucket)

      SimilarityQuery.call(
        embedding: vector,
        state: user_intent.state,
        coordinates: coordinates,
        radius_miles: radius
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

    def resolve_coordinates(user_intent)
      centroids = city_centroids
      state_data = centroids[user_intent.state] || {}
      city_data = state_data[user_intent.city]

      if city_data
        {latitude: city_data["latitude"], longitude: city_data["longitude"]}
      else
        first_city = state_data.values.first
        if first_city
          {latitude: first_city["latitude"], longitude: first_city["longitude"]}
        else
          {latitude: 40.7357, longitude: -74.1724}
        end
      end
    end

    def resolve_radius(travel_bucket)
      matching_rules.dig("radius_by_travel_bucket", travel_bucket) || 5
    end

    def city_centroids
      @city_centroids ||= YAML.load_file(Rails.root.join("config", "city_centroids.yml"))
    end

    def matching_rules
      @matching_rules ||= YAML.load_file(Rails.root.join("config", "matching_rules.yml"))
    end
  end
end
