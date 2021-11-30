class MyAccountsController < ApplicationController

  def show
    # @user
    @saved_pages = current_user.favorited_locations
    @alerts = current_user.alerts
    # @my_pages
  end
end
