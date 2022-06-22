class AlertSearchResults < ApplicationService
  attr_accessor :alert

  def initialize(alert)
    @alert = alert
  end

  def call
    search = Search.new(search_params)
    search.save
    search.results
  end

  def search_params
    {
      lat: nil,
      lon: nil,
      open_now: nil,
      services: build_services,
      causes: build_causes,
      keyword: alert.keyword.presence,
      distance: alert.distance.presence&.to_i,
      beneficiary_groups: build_beneficiary_groups,
      city: alert.city.presence, state: alert.state.presence,
      open_weekends: ActiveModel::Type::Boolean.new.cast(alert.open_weekends) ? true : nil
    }
  end

  def build_services
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

  def build_causes
    alert_causes_array = []
    alert.alert_causes.each do |alert_cause|
      alert_causes_array = alert_cause.cause.name
    end
    alert_causes_array
  end

  def build_beneficiary_groups
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
