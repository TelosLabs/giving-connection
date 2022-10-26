# frozen_string_literal: true

module SearchesHelper
  MIN_REQUIRED_PAGES = 1

  def list_of_filters(object)
    list = []
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list << object.services&.map(&:last)&.flatten
    list << object.causes&.flatten
    list << "Open On Weekends" if object.open_weekends.present?
    list << "#{kilometers_to_miles(object.distance).to_i} mi" if object.distance.present?
    list.flatten.compact
  end

  def selected_pills(tab_pills, type)
    return '' unless params[:search] && params[:search][type].present?

    tab_pills = tab_pills.map(&:name)
    search = params[:search][type.to_sym]
    search = search.values.flatten if type.include?('services') || type.include?('beneficiary_groups')
    tab_pills & search
  end

  def list_of_services(object, top_10_services)
    list = []
    top_10_services = top_10_services.map(&:name)
    list << object.services&.map(&:last)&.flatten
    list.flatten.compact - top_10_services
  end

  def list_of_causes(object, top_10_causes)
    list = []
    top_10_causes = top_10_causes.map(&:name)
    list << object.causes&.flatten
    list.flatten.compact - top_10_causes
  end

  def list_of_beneficiary_groups(object, top_10_beneficiary_groups)
    list = []
    top_10_beneficiary_groups = top_10_beneficiary_groups.map(&:name)
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list.flatten.compact - top_10_beneficiary_groups
  end

  def kilometers_to_miles(kms)
    kilometers = kms.to_f
    kilometers / 1.6
  end
end
