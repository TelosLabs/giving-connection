# frozen_string_literal: true

module SmartMatch
  class QuizzesController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized

    def show
      @step = current_step
      @total_steps = total_steps
      @user_type = session[:smart_match_user_type]

      step_info = SmartMatch::QuizStepConfig.section_for(@user_type, @step, support_for: session[:smart_match_support_for])
      @section_number = step_info[:number]
      @section_name = step_info[:name]
      @step_title = step_info[:title]
      @step_subtitle = step_info[:subtitle]
      @step_partial = SmartMatch::QuizStepConfig.partial_for(@user_type, @step)
      @is_final_step = @step == @total_steps
      @section_map = SmartMatch::QuizStepConfig.section_map_for(@user_type)
      @session_answers = quiz_session_answers
    end

    def destroy
      session.keys.select { |k| k.to_s.start_with?("smart_match_") }.each { |k| session.delete(k) }
      # The quiz X button exits to the landing page; retake buttons restart the
      # quiz. Either way all progress is wiped above. A cleared session resets
      # the wizard to step 1, so restarting lands on the first question.
      if params[:return_to] == "home"
        redirect_to smart_match_root_path
      else
        redirect_to smart_match_quiz_path
      end
    end

    def update
      result = SmartMatch::QuizNavigator.call(
        session: session,
        params: quiz_params,
        step: current_step
      )

      if result[:completed]
        intent = build_user_intent_for_validation
        if intent.valid?
          redirect_to smart_match_confirmation_path
        else
          flash[:alert] = intent.errors.full_messages.to_sentence.presence ||
            "Please answer all required questions."
          # Send the user back to the first incomplete step (state, then causes).
          session[:smart_match_step] = first_incomplete_step
          redirect_to smart_match_quiz_path
        end
      else
        redirect_to smart_match_quiz_path
      end
    end

    private

    def quiz_session_answers
      {
        user_type: session[:smart_match_user_type],
        support_for: session[:smart_match_support_for],
        self_description: Array(session[:smart_match_self_description]),
        situation: session[:smart_match_situation],
        city: session[:smart_match_city],
        state: session[:smart_match_state],
        city_choice: session[:smart_match_city_choice],
        location_scope: session[:smart_match_location_scope],
        travel_bucket: session[:smart_match_travel_bucket],
        causes: Array(session[:smart_match_causes]),
        prefs: Array(session[:smart_match_prefs]),
        language: session[:smart_match_language],
        age_range: session[:smart_match_age_range],
        gender_identity: session[:smart_match_gender_identity],
        race_ethnicity: session[:smart_match_race_ethnicity],
        donation_style: Array(session[:smart_match_donation_style]),
        giving_inspiration: Array(session[:smart_match_giving_inspiration]),
        donor_communities: Array(session[:smart_match_donor_communities]),
        impact_location: session[:smart_match_impact_location],
        donor_involvement: session[:smart_match_donor_involvement],
        volunteer_involvement: Array(session[:smart_match_volunteer_involvement]),
        volunteer_type: Array(session[:smart_match_volunteer_type]),
        volunteer_format: session[:smart_match_volunteer_format],
        volunteer_time: session[:smart_match_volunteer_time]
      }
    end

    def quiz_params
      params.permit(:user_type, :support_for, :situation, :city_selection, :location_scope_choice, :state, :city, :travel_bucket,
        :language_input, :direction, :target_step, :impact_location, :donor_involvement,
        :volunteer_format, :volunteer_time,
        :age_range, :gender_identity, :race_ethnicity,
        self_description: [], causes: [], prefs: [], donation_style: [], giving_inspiration: [], donor_communities: [],
        volunteer_involvement: [], volunteer_type: [])
    end

    def current_step
      (session[:smart_match_step] || 1).to_i
    end

    def total_steps
      SmartMatch::QuizNavigator.total_steps_for(
        session[:smart_match_user_type]
      )
    end

    def build_user_intent_for_validation
      UserIntent.from_session(
        session_answers: quiz_session_answers,
        user_type: session[:smart_match_user_type]
      )
    end

    # Step the user back to the first required field they did not provide.
    # Conservative mapping: state is asked early, causes near the end.
    def first_incomplete_step
      return 1 if session[:smart_match_user_type].blank?
      # State is only required for a local (city-based) search; nationwide /
      # international selections carry no state.
      return state_step if local_scope_session? && session[:smart_match_state].blank?
      return causes_step if Array(session[:smart_match_causes]).empty?
      1
    end

    # The state is captured on the location / city-selection step, whose
    # position differs by flow (see QuizStepConfig::STEP_PARTIAL_MAP and
    # QuizNavigator). Donors answer an "impact location" question at step 6 and
    # pick their city/state at step 7; service_seekers and volunteers pick
    # city/state at step 6. Routing to a hardcoded step 2 would send users to an
    # unrelated question (support_for / causes) that never captures state.
    def state_step
      case session[:smart_match_user_type].to_s
      when "donor" then 7
      else 6
      end
    end

    # The causes question lives at a different step per flow (see
    # QuizStepConfig::STEP_PARTIAL_MAP): service_seekers answer it at step 4,
    # donors/volunteers at step 2. Routing to a hardcoded step 3 would send a
    # service_seeker past their missing causes field.
    def causes_step
      case session[:smart_match_user_type].to_s
      when "service_seeker" then 4
      else 2
      end
    end

    def local_scope_session?
      !QuizNavigator::NON_LOCAL_SCOPES.include?(session[:smart_match_location_scope].to_s)
    end
  end
end
