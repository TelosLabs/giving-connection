# frozen_string_literal: true

class FavoriteLocationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_session_favorite

  include Pundit

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def create
    @location = Location.find(params[:location_id])
    @new_favorite_location = FavoriteLocation.new(location: @location, user: current_user)

    respond_to_request if @new_favorite_location.save
  end

  def destroy
    @favorite_location = current_user.fav_locs.find(params[:id])
    @user = @favorite_location.user
    @location = @favorite_location.location

    respond_to_request if @favorite_location.destroy
  end

  private

  def set_session_favorite
    unless user_signed_in?
      session[:marker_infowindow] = params[:location_id]
      session[:fav_loc_id] = params[:location_id]
      redirect_to user_session_path
    end
  end

  def respond_to_request
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to my_account_path }
    end
  end
end
