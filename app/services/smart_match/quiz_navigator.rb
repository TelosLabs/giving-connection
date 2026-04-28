# frozen_string_literal: true

module SmartMatch
  class QuizNavigator < ApplicationService
    STEPS_BY_USER_TYPE = {
      "service_seeker" => 9,
      "volunteer"      => 8,
      "donor"          => 9
    }.freeze

    DEFAULT_STEPS = 4

    # Maps each form parameter name to its session key.
    # Parameters that write to multiple keys (city_selection, state/city) are
    # handled separately in #store_city_selection and #store_location.
    PARAM_SESSION_MAP = {
      user_type:            :smart_match_user_type,
      support_for:          :smart_match_support_for,
      self_description:     :smart_match_self_description,
      situation:            :smart_match_situation,
      donation_style:       :smart_match_donation_style,
      giving_inspiration:   :smart_match_giving_inspiration,
      donor_communities:    :smart_match_donor_communities,
      impact_location:      :smart_match_impact_location,
      donor_involvement:    :smart_match_donor_involvement,
      volunteer_involvement: :smart_match_volunteer_involvement,
      volunteer_type:       :smart_match_volunteer_type,
      volunteer_format:     :smart_match_volunteer_format,
      volunteer_time:       :smart_match_volunteer_time,
      causes:               :smart_match_causes,
      prefs:                :smart_match_prefs,
      language_input:       :smart_match_language,
      travel_bucket:        :smart_match_travel_bucket,
      age_range:            :smart_match_age_range,
      gender_identity:      :smart_match_gender_identity,
      race_ethnicity:       :smart_match_race_ethnicity
    }.freeze

    CITY_TO_STATE = {
      "Atlantic City" => "NJ",
      "Los Angeles"   => "CA",
      "Nashville"     => "TN"
    }.freeze

    attr_reader :session, :params, :step

    def initialize(session:, params:, step:)
      @session = session
      @params  = params
      @step    = step
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
      PARAM_SESSION_MAP.each do |param_key, session_key|
        session[session_key] = params[param_key] if params[param_key].present?
      end

      store_city_selection if params[:city_selection].present?
      store_location       if params[:state].present?
    end

    def store_city_selection
      city = params[:city_selection]
      session[:smart_match_city]  = city
      session[:smart_match_state] = CITY_TO_STATE[city] if CITY_TO_STATE.key?(city)
    end

    def store_location
      session[:smart_match_state] = params[:state]
      session[:smart_match_city]  = params[:city]
    end

    def advance_step
      next_step = step + 1
      total     = self.class.total_steps_for(session[:smart_match_user_type])

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
