class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :check_auth

  def index; end

  def check_auth
    unless user_signed_in?
      redirect_to :controller => :landing_page
    end
  end
end
