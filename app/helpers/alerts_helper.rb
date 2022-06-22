# frozen_string_literal: true

module AlertsHelper
  def list_all_filters(object)
    list = []
    list << list_filter_variables(object)
    list << "Open Now" if object.open_now.present?
    list << "Open On Weekends" if object.open_weekends.present?
    list << "#{kilometers_to_miles(object.distance).to_i} mi" if object.distance.present?
    list.flatten.compact
  end

  def list_filter_variables(object)
    list = []
    list = assign_causes(object, list)
    list = assign_services(object, list)
    list = assign_beneficiaries(object, list)
    list.flatten.compact
  end

  def assign_causes(object, list)
    return list unless object.alert_causes.present?

    object.alert_causes.each do |alert_cause|
      list << alert_cause.cause.name
    end
    list
  end

  def assign_services(object, list)
    return list unless object.alert_services.present?

    object.alert_services.each do |alert_service|
      list << alert_service.service.name
    end
    list
  end

  def assign_beneficiaries(object, list)
    return list unless object.alert_beneficiaries.present?

    object.alert_beneficiaries.each do |beneficiary|
      list << beneficiary.beneficiary_subcategory.name
    end
    list
  end
end
