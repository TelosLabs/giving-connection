# frozen_string_literal: true

module SmartMatch
  class LandingController < ApplicationController
    skip_before_action :authenticate_user!
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped

    def show
    end
  end
end
