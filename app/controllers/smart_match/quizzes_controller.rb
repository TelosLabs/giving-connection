# frozen_string_literal: true

module SmartMatch
  class QuizzesController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized

    def show
      @step = current_step
      @total_steps = total_steps
      @user_type = session[:smart_match_user_type]

      step_info = SmartMatch::QuizStepConfig.section_for(@user_type, @step)
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
      redirect_to smart_match_root_path
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
        self_description: session[:smart_match_self_description],
        situation: session[:smart_match_situation],
        city: session[:smart_match_city],
        state: session[:smart_match_state],
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
      params.permit(:user_type, :support_for, :self_description, :situation, :city_selection, :state, :city, :travel_bucket,
        :language_input, :direction, :impact_location, :donor_involvement,
        :volunteer_format, :volunteer_time,
        :age_range, :gender_identity, :race_ethnicity,
        causes: [], prefs: [], donation_style: [], giving_inspiration: [], donor_communities: [],
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
      return 2 if session[:smart_match_state].blank?
      return 3 if Array(session[:smart_match_causes]).empty?
      1
    end
  end
end
