class AutocompletesController < ApplicationController
  skip_before_action :authenticate_user!

  include Pundit

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def show
    @suggestions = %w[1 s orange apple banana]
    render layout: false
  end
end
