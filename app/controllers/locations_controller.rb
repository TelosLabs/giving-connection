# frozen_string_literal: true

class LocationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @location = Location.find(params[:id])
    authorize @location
    @youtube_video_id = you_toube_id(@location.youtube_video_link)
  end

  def new
    @location = Location.new
    authorize @location
  end

  def delete
    @location = Location.find(params[:id])
    @ocation.destroy
  end

  private

  def create_params
    params.require(:location).permit(:address, :longitude, :latitude, :youtube_video_link)
  end

  def you_toube_id(youtube_video_link)
    regex = /(?:youtube(?:-nocookie)?\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/
    match = regex.match(youtube_video_link)
    (match && !match[1].blank?) ? match[1] : nil
  end
end
