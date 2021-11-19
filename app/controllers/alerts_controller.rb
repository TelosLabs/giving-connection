class AlertsController < ApplicationController

	def new
		@alert = Alert.new()
		@alert_params = params['alert_params']
	end

	def create
		new_alert = Alert.new(alert_params)
		new_alert.user = current_user
		if new_alert.save
		  redirect_to root_path
		else
		  puts "Alert not created"
		end
	end

	def alert_params
		params.require(:alert).permit(:frequency, :keyword, :city, :state, :services, 
																	:beneficiary_groups, :distance, :open_now, :open_weekends)
	end


end
