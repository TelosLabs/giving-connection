# frozen_string_literal: true

class AlertsController < ApplicationController
  include Pundit

  after_action :verify_authorized, except: :destroy

  def new
    @alert = Alert.new
    @alert_params = params['alert_params']
  end

  def create
    new_alert = Alert.new(alert_params)
    new_alert.user = current_user
    # binding.pry
    if new_alert.save
      schedule_next_alert(new_alert)
      redirect_to root_path
      @type = 'notice'
      @message = "Alert created successfully"
    else
      @type = 'alert'
      @message = "Could not create alert. Try later"
    end
    respond_to do |format|
      format.js { render :index }
    end
  end

  def edit
		@alert = Alert.find(params[:id])
  end

	def destroy
		@alert = Alert.find(params[:id])
		@alert.destroy
    flash[:success] = "The alert was successfully deleted."
    redirect_to my_account_path
	end

  def alert_params
    params.require(:search).permit(:distance, :city, :state, :beneficiary_groups,
                                  :services, :open_now, :open_weekends, :keyword, :frequency)
  end

  def schedule_next_alert(alert)
    case alert.frequency
    when 'daily'
      alert.update!(next_alert: Date.today + 1)
    when 'weekly'
      alert.update!(next_alert: Date.today + 7)
    when 'monthly'
      alert.update!(next_alert: Date.today + 30)
    end
  end
end
