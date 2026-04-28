# frozen_string_literal: true

module SmartMatch
  class ResultsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      @user_type = session[:smart_match_user_type]
      process_quiz_results if quiz_completed?
    rescue SmartMatch::EmbeddingUnavailableError
      @embedding_unavailable = true
    end

    private

    def quiz_completed?
      session[:smart_match_user_type].present? && session[:smart_match_causes].present?
    end

    def process_quiz_results
      result = SmartMatch::SubmissionProcessor.call(
        session_answers: quiz_session_answers,
        user_type: session[:smart_match_user_type],
        session_id: session.id.to_s,
        user: current_user
      )
      @submission = result[:submission]
      @results = @submission.organization_matches.includes(:organization).order(:rank).limit(3)
    end

    def quiz_session_answers
      {
        state: session[:smart_match_state],
        city: session[:smart_match_city],
        travel_bucket: session[:smart_match_travel_bucket],
        causes: session[:smart_match_causes],
        preferences: session[:smart_match_prefs],
        language_input: session[:smart_match_language]
      }
    end
  end
end
