# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  def send_alert(alert)
    @alert = alert
    search = Search.new(search_params(alert))
    search.save
    @new_locations = search.results.select {|result| result.created_at > alert.next_alert || result.updated_at > alert.next_alert}
    attachments.inline["send_alert_logo.png"] = File.read("#{Rails.root}/app/assets/images/send_alert_logo.png")
    unless @new_locations.empty?
      mail from: 'Giving Connection <notification@teloslabs.co>', to: alert.user.email, subject: "Giving Connection - #{@new_locations.count} New Locations Added !"
    end
  end

  def search_params(alert)
    filters = {
      lat: nil,
      lon: nil,
      open_now: nil,
      services: build_services(alert),
      keyword: alert.keyword.presence,
      distance: alert.distance.presence&.to_i,
      beneficiary_groups: build_beneficiary_groups(alert),
      city: alert.city.presence, state: alert.state.presence,
      open_weekends: ActiveModel::Type::Boolean.new.cast(alert.open_weekends) ? true : nil,
    }
    filters
  end

  def build_services(alert)
    alert_services_hash = {}
    alert.alert_services.each do |alert_service|
      if alert_services_hash.keys.include?(alert_service.service.cause.name)
        alert_services_hash[alert_service.service.cause.name] << alert_service.service.name
      else
        alert_services_hash[alert_service.service.cause.name] = [alert_service.service.name]
      end
    end
    alert_services_hash
  end

  def build_beneficiary_groups(alert)
    alert_beneficiaries_hash = {}
    alert.alert_beneficiaries.each do |alert_beneficiariy|
      if alert_beneficiaries_hash.keys.include?(alert_beneficiariy.beneficiary_subcategory.beneficiary_group.name)
        alert_beneficiaries_hash[alert_beneficiariy.beneficiary_subcategory.beneficiary_group.name] << alert_beneficiariy.beneficiary_subcategory.name
      else
        alert_beneficiaries_hash[alert_beneficiariy.beneficiary_subcategory.beneficiary_group.name] = [alert_beneficiariy.beneficiary_subcategory.name]
      end
    end
    alert_beneficiaries_hash
  end
end
