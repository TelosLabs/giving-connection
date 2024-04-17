class CitiesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    city_name = params[:city]
    cookies[:city] = city_name

    skip_authorization
    redirect_to root_path
  end
end
