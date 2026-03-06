# frozen_string_literal: true

module SmartMatch
  class QuizNavigator < ApplicationService
    STEPS_BY_USER_TYPE = {
      "service_seeker" => 5,
      "volunteer" => 4,
      "donor" => 4
    }.freeze

    DEFAULT_STEPS = 4

    attr_reader :session, :params, :step

    def initialize(session:, params:, step:)
      @session = session
      @params = params
      @step = step
    end

    def call
      going_back? ? navigate_back : navigate_forward
    end

    def self.total_steps_for(user_type)
      STEPS_BY_USER_TYPE.fetch(user_type.to_s, DEFAULT_STEPS)
    end

    private

    def going_back?
      params[:direction] == "back"
    end

    def navigate_back
      session[:smart_match_step] = [step - 1, 1].max
      {completed: false}
    end

    def navigate_forward
      store_answers
      advance_step
    end

    def store_answers
      store_user_type if params[:user_type].present?
      store_location if params[:state].present?
      store_causes if params[:causes].present?
      store_preferences if params[:prefs].present?
      store_language if params[:language_input].present?
      store_travel_bucket if params[:travel_bucket].present?
    end

    def store_user_type
      session[:smart_match_user_type] = params[:user_type]
    end

    def store_location
      session[:smart_match_state] = params[:state]
      session[:smart_match_city] = params[:city]
    end

    def store_causes
      session[:smart_match_causes] = params[:causes]
    end

    def store_preferences
      session[:smart_match_prefs] = params[:prefs]
    end

    def store_language
      session[:smart_match_language] = params[:language_input]
    end

    def store_travel_bucket
      session[:smart_match_travel_bucket] = params[:travel_bucket]
    end

    def advance_step
      next_step = step + 1
      total = self.class.total_steps_for(session[:smart_match_user_type])

      if next_step > total
        session[:smart_match_step] = total
        {completed: true}
      else
        session[:smart_match_step] = next_step
        {completed: false}
      end
    end
  end
end
