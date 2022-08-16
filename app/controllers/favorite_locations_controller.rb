# frozen_string_literal: true

class FavoriteLocationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_session_favorite

  include Pundit

  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def create
    @location = Location.find(params[:location_id])
    new_favorite_location = FavoriteLocation.new(location: @location, user: current_user)
    if new_favorite_location.save
      if params["origin"] == "location_show"
        redirect_to location_path(@location)
      end
      data = { marked_partial: render_to_string(partial: "shared/marked", locals: { user_id: current_user, id: @location.id }), 
                location_id: @location.id, method: "create" }
      ActionCable.server.broadcast("everyone", data)
    end
  end

  def destroy
    @favorite_location = current_user.fav_locs.find(params[:id])
    if @favorite_location.destroy
      if params["origin"] == "location_show"
        redirect_to location_path(@favorite_location.location)
      end
      data = { unmarked_partial: render_to_string(partial: "shared/unmarked", locals: { id: @favorite_location.location.id }), 
                 location_id: @favorite_location.location.id, favorite_location_id: @favorite_location.id }
      ActionCable.server.broadcast("everyone", data)
    end
  end

  private

  def set_session_favorite
    unless user_signed_in?
      session[:location_id] = params[:location_id]
      session[:fav_loc_id] = params[:location_id]
      redirect_to user_session_path
    end
  end
end
