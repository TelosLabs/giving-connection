class FavoriteLocationsController < ApplicationController

	def create
		@location = Location.find(params[:location_id])
		new_favorite_location = FavoriteLocation.new(location: @location, user: current_user)
		new_favorite_location.save
		# TODO return json
	end

	def destroy
		@favorite_location = FavoriteLocation.find(params[:id])
		@favorite_location.destroy
		# TODO return json
	end

end
