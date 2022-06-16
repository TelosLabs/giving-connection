# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  def send_alert(alert)
    @alert = alert
    set_results
    unless @new_locations.empty?
      mail from: 'Giving Connection <info@givingconnection.org>', to: alert.user.email, subject: "Giving Connection - #{@new_locations.count} New Locations Added !"
      update_alert_search_results
    end
  end

  def set_results
    search_results = AlertSearchResults.new(@alert).call
    @new_locations = search_results.where.not(id: @alert.search_results)
  end

  def update_alert_search_results
    search_results = @alert.search_results + @new_locations.pluck(:id)
    @alert.update(search_results: search_results)
  end
end
