# frozen_string_literal: true

class Alerts::SendSavedSearchesAlertEmailsJob < ActiveJob::Base
  def perform(alert_id)
    @alert = Alert.find(alert_id)
    if @alert.next_alert == Date.today
      send_alert_email
      update_next_alert
    end
  end

  private

  def send_alert_email
    SavedSearchAlertMailer.send_alert(@alert).deliver_later
  end

  def update_next_alert
    case @alert.frequency
    when "daily"
      @alert.update!(next_alert: 1.day.from_now)
    when "weekly"
      @alert.update!(next_alert: 1.week.from_now)
    when "monthly"
      @alert.update!(next_alert: 1.month.from_now)
    end
  end
end
