# frozen_string_literal: true

class MyAccountsController < ApplicationController
  skip_after_action :verify_authorized
  include SearchesHelper

  def show
    @saved_pages = current_user.favorited_locations
    @alerts = current_user.alerts.order(:id)
    @my_organizations = current_user.administrated_organizations
    @org_id = params[:org_id] || @my_organizations.first&.id
    @organization = Organization.find_by(id: @org_id)
    @events = @organization.events.order(:start_time) if @organization
  end
end
