# frozen_string_literal: true

class MyAccountsController < ApplicationController
  skip_after_action :verify_authorized
  include SearchesHelper

  def show
    @saved_pages = current_user.favorited_locations
    @alerts = current_user.alerts.order(:id)
    @my_organizations = current_user.administrated_organizations
    puts "tz: #{request.headers['HTTP_TIMEZONE']}"
    @events = @my_organizations.flat_map(&:events).sort_by(&:start_time)
  end
end
