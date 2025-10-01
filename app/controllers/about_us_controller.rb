class AboutUsController < ApplicationController
  skip_before_action :authenticate_user!

  include Pundit::Authorization

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def index
  end
end
