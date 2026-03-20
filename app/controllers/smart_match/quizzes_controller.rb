# frozen_string_literal: true

module SmartMatch
  class QuizzesController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized

    def show
      @step = current_step
      @total_steps = total_steps
      @user_type = session[:smart_match_user_type]
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
        redirect_to smart_match_confirmation_path
      else
        redirect_to smart_match_quiz_path
      end
    end

    private

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
  end
end
