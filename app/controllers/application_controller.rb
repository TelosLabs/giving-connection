# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?

  include Pagy::Backend
  before_action :authenticate_user!
  include Pundit

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    location = request.headers["Turbo-Frame"].present? ? my_account_path : request.fullpath
    store_location_for(:user, location)
  end

  def after_sign_in_path_for(resource_or_scope)
    create_instances_from_session
    stored_location_for(resource_or_scope) || super
  end

  def create_instances_from_session
    if session[:fav_loc_id].present?
      FavoriteLocation.create(location_id: session[:fav_loc_id], user: current_user)
      session.delete(:fav_loc_id)
    end
  end

  def user_not_authorized
    flash[:error] = 'You are not allowed to perform this action'
    redirect_to root_path
  end
end
