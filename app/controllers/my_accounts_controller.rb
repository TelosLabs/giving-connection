# frozen_string_literal: true

class MyAccountsController < ApplicationController
  skip_after_action :verify_authorized
  include SearchesHelper

  def show
    @saved_pages = current_user.favorited_locations
    @alerts = current_user.alerts
    @my_organizations = current_user.administrated_organizations
  end
end
