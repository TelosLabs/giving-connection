# frozen_string_literal: true

class AlertsController < ApplicationController
  def new
    @alert = Alert.new
    @alert_params = params['alert_params']
  end

  def create
    new_alert = Alert.new(alert_params)
    new_alert.user = current_user
    if new_alert.save
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

  def alert_params
    params.require(:search).permit(:distance, :city, :state, :beneficiary_groups,
                                  :services, :open_now, :open_weekends, :keyword, :frequency)
  end
end
