# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  def send_alert(alert)
  	@alert = alert
    mail to: alert.user.email, subject: '#' 
  end
end