# frozen_string_literal: true

class SavedSearchAlertMailer < ApplicationMailer
  def send_alert(alert)
    @alert = alert
    locations = Search.new(create_filters(alert)).save
    @new_locations = locations.where("created_at > ?", alert.next_alert)
    if @new_locations.count > 0 
      mail to: alert.user.email, subject: "Giving Connection - #{@new_locations.count} New Locations Added !" 
    end
  end

  def create_filters(alert)
    filters = {
      address: { city: alert.city.presence, state: alert.state.presence, zipcode: alert.zipcode.presence },
      open_weekends: ActiveModel::Type::Boolean.new.cast(alert.open_weekends),
      services: build_services(alert),
      beneficiary_groups: build_beneficiary_groups(alert), 
      distance: alert.distance.presence&.to_i
    }
    filters
  end

  def build_services(alert)
    alert_services_hash = {}
    alert.alert_services.each do |alert_service|
      if alert_services_hash.keys.include?(alert_service.service.cause.name)
        alert_services[alert_service.service.cause.name] << alert_service.service.name
      else
        alert_services[alert_service.service.cause.name] = [alert_service.service.name]
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
        alert_beneficiaries_hash[alert_beneficiariy.beneficiary_subcategory.beneficiary_group.name] = alert_beneficiariy.beneficiary_subcategory.name
      end
    end
    alert_beneficiaries_hash
  end
end
