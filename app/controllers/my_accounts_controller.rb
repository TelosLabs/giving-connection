class MyAccountsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    # @user
    @saved_pages = current_user.favorited_locations
    @alerts = current_user.alerts
    # @my_pages
  end
end
