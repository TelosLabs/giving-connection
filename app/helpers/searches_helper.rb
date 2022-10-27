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

  def build_params_array(type)
    arr = params[:search][type.to_sym]
    arr = arr.values.flatten if type.include?('services') || type.include?('beneficiary_groups')
    arr
  end

  def selected_pills(tab_pills, type)
    search_params = build_params_array(type)
    tab_pills & search_params
  end

  def selected_advanced_filters(tab_pills, type)
    return [] unless params[:search] && params[:search][type].present?

    search_params = build_params_array(type)
    search_params - tab_pills
  end

  def kilometers_to_miles(kms)
    kilometers = kms.to_f
    kilometers / 1.6
  end
end
