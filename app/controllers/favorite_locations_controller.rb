class FavoriteLocationsController < ApplicationController

	def create
		@location = Location.find(params['location'])
		new_favorite_location = FavoriteLocation.new(location: @location, user: current_user)
		if new_favorite_location.save
			redirect_to searches_path
		end
	end

	def destroy
		@favorite_location = FavoriteLocation.find(params[:id])
		@favorite_location.destroy
		redirect_to searches_path
	end


end
