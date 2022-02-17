# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?

  include Pagy::Backend
  before_action :authenticate_user!
  include Pundit

  after_action :verify_authorized, except: :index, unless: :skip_pundit?
  after_action :verify_policy_scoped, only: :index, unless: :skip_pundit?
  before_action :configure_permitted_parameters, if: :devise_controller?

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
     store_location_for(:user, request.fullpath)
   end

   def after_sign_in_path_for(resource_or_scope)
     stored_location_for(resource_or_scope) || super
   end
end
