class EventCalendarController < ApplicationController
    # Ignores auth for now
    skip_before_action :authenticate_user!, only: [:index] 
    # Ignores policy for now
    skip_after_action :verify_policy_scoped, only: [:index]
  
    def index
      # Add any logic for the Event Calendar page here
    end
  end