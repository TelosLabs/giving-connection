# frozen_string_literal: true

module AlertsHelper
  def list_all_filters(object)
    list = []
    list << list_services_and_beneficiary_filters(object)
    list << "Open Now" if object.open_now.present?
    list << "Open On Weekends" if object.open_weekends.present?
    list << "#{kilometers_to_miles(object.distance).to_i} mi" if object.distance.present?
    list.flatten.compact
  end

  def list_services_and_beneficiary_filters(object)
    list = []
    if object.alert_services.present?
      object.alert_services.each do |services|
        list << services.service.name
      end
    end
    if object.alert_beneficiaries.present?
      object.alert_beneficiaries.each do |beneficiary|
        list << beneficiary.beneficiary_subcategory.name
      end
    end
    list.flatten.compact
  end
end
