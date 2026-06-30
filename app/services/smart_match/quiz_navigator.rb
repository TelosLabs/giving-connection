# frozen_string_literal: true

module SmartMatch
  class QuizNavigator < ApplicationService
    STEPS_BY_USER_TYPE = {
      "service_seeker" => 10,
      "volunteer" => 9,
      "donor" => 10
    }.freeze

    DEFAULT_STEPS = 4

    # The service_seeker distance/"travel" step. It is meaningless when the
    # user picked a nationwide/international scope (no specific location), so
    # it is skipped for those users. It is the only distance step in any flow.
    SERVICE_SEEKER_TRAVEL_STEP = 7

    NON_LOCAL_SCOPES = %w[national international].freeze

    # Maps each form parameter name to its session key.
    # Parameters that write to multiple keys (city_selection, state/city) are
    # handled separately in #store_city_selection and #store_location.
    PARAM_SESSION_MAP = {
      user_type: :smart_match_user_type,
      support_for: :smart_match_support_for,
      self_description: :smart_match_self_description,
      situation: :smart_match_situation,
      donation_style: :smart_match_donation_style,
      giving_inspiration: :smart_match_giving_inspiration,
      donor_communities: :smart_match_donor_communities,
      impact_location: :smart_match_impact_location,
      donor_involvement: :smart_match_donor_involvement,
      volunteer_involvement: :smart_match_volunteer_involvement,
      volunteer_type: :smart_match_volunteer_type,
      volunteer_format: :smart_match_volunteer_format,
      volunteer_time: :smart_match_volunteer_time,
      causes: :smart_match_causes,
      prefs: :smart_match_prefs,
      language_input: :smart_match_language,
      travel_bucket: :smart_match_travel_bucket,
      age_range: :smart_match_age_range,
      gender_identity: :smart_match_gender_identity,
      race_ethnicity: :smart_match_race_ethnicity
    }.freeze

    attr_reader :session, :params, :step

    def initialize(session:, params:, step:)
      @session = session
      @params = params
      @step = step
    end

    def call
      case params[:direction]
      when "back" then navigate_back
      when "goto" then navigate_goto
      else navigate_forward
      end
    end

    def self.total_steps_for(user_type)
      STEPS_BY_USER_TYPE.fetch(user_type.to_s, DEFAULT_STEPS)
    end

    private

    def navigate_back
      total = self.class.total_steps_for(session[:smart_match_user_type])
      prev_step = next_visible_step(step - 1, total, :backward)
      session[:smart_match_step] = [prev_step, 1].max
      {completed: false}
    end

    # Jump to a specific step. Only allowed backward (target <= current step)
    # so users can't skip past unanswered questions via the progress bar.
    def navigate_goto
      target = params[:target_step].to_i
      total = self.class.total_steps_for(session[:smart_match_user_type])
      target = target.clamp(1, [step, total].min)
      session[:smart_match_step] = target
      {completed: false}
    end

    def navigate_forward
      store_answers
      advance_step
    end

    def store_answers
      PARAM_SESSION_MAP.each do |param_key, session_key|
        # params.key? (not .present?) so users can deselect multi-selects
        # by submitting an empty array — .present? would skip empty values
        # and leave a previous selection in place.
        session[session_key] = params[param_key] if params.key?(param_key)
      end

      store_location_answer
    end

    # Location is captured one of three ways, and we branch so the (always
    # present in the DOM) "Other" panel can't overwrite a preset city card:
    #   * preset city card -> city_selection holds the city; state is derived
    #   * "Other" card      -> city_selection == "other"; the revealed
    #                          state/city fields carry the real values
    #   * direct state/city -> legacy path used when no city_selection is sent
    def store_location_answer
      case params[:city_selection]
      when "other"
        store_local_scope
        store_other_location
      when "national", "international"
        store_scope_location(params[:city_selection])
      when nil, ""
        if params[:state].present?
          store_local_scope
          store_location
        end
      else
        store_local_scope
        store_city_selection
      end
    end

    # Nationwide/international selections carry no specific location — clear any
    # previously captured city/state so geographic filtering is skipped.
    def store_scope_location(scope)
      session[:smart_match_location_scope] = scope
      session[:smart_match_state] = nil
      session[:smart_match_city] = nil
    end

    def store_local_scope
      session[:smart_match_location_scope] = "local"
    end

    def store_other_location
      session[:smart_match_state] = params[:state] if params[:state].present?
      session[:smart_match_city] = params[:city].to_s.strip.presence
    end

    def store_city_selection
      city = params[:city_selection]
      session[:smart_match_city] = city
      session[:smart_match_state] = state_for_city(city) if state_for_city(city)
    end

    def state_for_city(city)
      centroids = SmartMatch::CITY_CENTROIDS
      centroids.each do |state, cities|
        return state if cities.is_a?(Hash) && cities.key?(city)
      end
      nil
    end

    def store_location
      session[:smart_match_state] = params[:state]
      session[:smart_match_city] = params[:city]
    end

    def advance_step
      total = self.class.total_steps_for(session[:smart_match_user_type])
      next_step = next_visible_step(step + 1, total, :forward)

      if next_step > total
        session[:smart_match_step] = total
        {completed: true}
      else
        session[:smart_match_step] = next_step
        {completed: false}
      end
    end

    # Walk past any skipped steps in the given direction. Total step count is
    # unchanged (the flow simply jumps over the hidden step), so final-step
    # detection and the progress bar need no renumbering.
    def next_visible_step(candidate, total, direction)
      delta = (direction == :forward ? 1 : -1)
      candidate += delta while candidate.between?(1, total) && skip_step?(candidate)
      candidate
    end

    def skip_step?(step_number)
      session[:smart_match_user_type] == "service_seeker" &&
        step_number == SERVICE_SEEKER_TRAVEL_STEP &&
        NON_LOCAL_SCOPES.include?(session[:smart_match_location_scope].to_s)
    end
  end
end
