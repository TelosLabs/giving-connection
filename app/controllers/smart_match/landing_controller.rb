# frozen_string_literal: true

module SmartMatch
  class LandingController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
      # Mirrors ResultsController#quiz_completed? — when the quiz has been
      # answered we can take the user straight to their saved results.
      @has_results = session[:smart_match_user_type].present? && session[:smart_match_causes].present?
    end
  end
end
