class Alerts::SendSavedSearchesAlertEmailsJob < ActiveJob::Base
  def perform 
    Alert.all.each do |alert|
    if alert.next_alert == Date.today  
      send_alert_email(alert)
      update_next_alert(alert)
    end 
  end

  def send_alert_email(alert)
    SavedSearchAlertMailer.send_saved_search_alert(alert).deliver_later
  end

  def update_next_alert(alert)
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