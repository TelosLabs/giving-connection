class ReviewAndPublishController < ApplicationController
    def show
      # Your logic here
    end
    skip_before_action :authenticate_user!
  
    include Pundit
  
    skip_after_action :verify_policy_scoped
    skip_after_action :verify_authorized
  
    def index
    end
  end
  