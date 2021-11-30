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
      schedule_next_alert(new_alert)
      redirect_to root_path
    else
      puts 'Alert not created'
    end
  end

  def alert_params
    params.require(:alert).permit(:frequency, :keyword, :city, :state, :services,
                                  :beneficiary_groups, :distance, :open_now, :open_weekends)
  end

  def schedule_next_alert(alert)
    case alert.frequency
    when "daily"
      alert.update!(next_alert: Date.today + 1)
    when "weekly"
      alert.update!(next_alert: Date.today + 7)
    when "monthly"
      alert.update!(next_alert: Date.today + 30)
    end
  end
end
