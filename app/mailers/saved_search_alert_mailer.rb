# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  def send_saved_search_alert(_alert)
    mail(to: '#', subject: '#')
  end
end
