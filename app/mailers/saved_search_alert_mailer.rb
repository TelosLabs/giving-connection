# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  before_action :attach_gc_logo, only: :send_alert

  def send_alert(alert)
    @alert = alert
    set_results
    @alert_filters = build_alert_filters
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

  def build_alert_filters
    filters = AlertSearchResults.new(@alert).search_params
    beneficiary_groups = filters[:beneficiary_groups].values.flatten
    services = filters[:services].values.flatten
    beneficiary_groups.concat(services).join(", ")
  end

  def attach_gc_logo
    attachments.inline["send_alert_logo.png"] = File.read("#{Rails.root}/app/assets/images/send_alert_logo.png")
  end

  def attach_organizations_logos
    @new_locations&.each do |location|
      logo = location.organization.logo
      attachments.inline[logo.blob.filename.to_s] = { mime_type: logo.blob.content_type, content: logo.blob.download }
    end
  end
end
