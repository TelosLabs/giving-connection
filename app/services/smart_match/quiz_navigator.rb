# frozen_string_literal: true

module SmartMatch
  class QuizNavigator < ApplicationService
    STEPS_BY_USER_TYPE = {
      "service_seeker" => 9,
      "volunteer" => 8,
      "donor" => 9
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
      store_support_for if params[:support_for].present?
      store_self_description if params[:self_description].present?
      store_situation if params[:situation].present?
      store_city_selection if params[:city_selection].present?
      store_donation_style if params[:donation_style].present?
      store_giving_inspiration if params[:giving_inspiration].present?
      store_donor_communities if params[:donor_communities].present?
      store_impact_location if params[:impact_location].present?
      store_donor_involvement if params[:donor_involvement].present?
      store_volunteer_involvement if params[:volunteer_involvement].present?
      store_volunteer_type if params[:volunteer_type].present?
      store_volunteer_format if params[:volunteer_format].present?
      store_volunteer_time if params[:volunteer_time].present?
      store_location if params[:state].present?
      store_causes if params[:causes].present?
      store_preferences if params[:prefs].present?
      store_language if params[:language_input].present?
      store_travel_bucket if params[:travel_bucket].present?
      store_age_range if params[:age_range].present?
      store_gender_identity if params[:gender_identity].present?
      store_race_ethnicity if params[:race_ethnicity].present?
    end

    def store_user_type
      session[:smart_match_user_type] = params[:user_type]
    end

    def store_support_for
      session[:smart_match_support_for] = params[:support_for]
    end

    def store_self_description
      session[:smart_match_self_description] = params[:self_description]
    end

    def store_situation
      session[:smart_match_situation] = params[:situation]
    end

    def store_city_selection
      session[:smart_match_city] = params[:city_selection]
    end

    def store_donation_style
      session[:smart_match_donation_style] = params[:donation_style]
    end

    def store_giving_inspiration
      session[:smart_match_giving_inspiration] = params[:giving_inspiration]
    end

    def store_donor_communities
      session[:smart_match_donor_communities] = params[:donor_communities]
    end

    def store_impact_location
      session[:smart_match_impact_location] = params[:impact_location]
    end

    def store_donor_involvement
      session[:smart_match_donor_involvement] = params[:donor_involvement]
    end

    def store_volunteer_involvement
      session[:smart_match_volunteer_involvement] = params[:volunteer_involvement]
    end

    def store_volunteer_type
      session[:smart_match_volunteer_type] = params[:volunteer_type]
    end

    def store_volunteer_format
      session[:smart_match_volunteer_format] = params[:volunteer_format]
    end

    def store_volunteer_time
      session[:smart_match_volunteer_time] = params[:volunteer_time]
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

    def store_age_range
      session[:smart_match_age_range] = params[:age_range]
    end

    def store_gender_identity
      session[:smart_match_gender_identity] = params[:gender_identity]
    end

    def store_race_ethnicity
      session[:smart_match_race_ethnicity] = params[:race_ethnicity]
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
