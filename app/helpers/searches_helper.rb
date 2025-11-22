# frozen_string_literal: true

module SearchesHelper
  MIN_REQUIRED_PAGES = 1

  def parse_filters(object)
    filters = {}
    filters[:keywords] = object.keyword
    filters[:distance] = object.distance
    filters[:open_now] = object.open_now.present?
    filters[:open_weekends] = object.open_weekends.present?
    filters[:beneficiary_groups] = object.beneficiary_groups&.map(&:last)&.flatten
    filters[:services] = object.services&.map(&:last)&.flatten
    filters[:causes] = object.causes&.flatten
    filters
  end

  def list_of_filters(object)
    list = []
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list << object.services&.map(&:last)&.flatten
    list << object.causes&.flatten
    list << "Open Now" if object.open_now.present?
    list << "Open On Weekends" if object.open_weekends.present?
    list << "#{kilometers_to_miles(object.distance).to_i} mi" if object.distance.present?
    list.flatten.compact
  end

  def selected_(type, top_ten, search)
    search = search.values.flatten if search.is_a?(Hash)
    (type == "pills") ? top_ten.map(&:name) & search : search - top_ten.map(&:name)
  end

  def kilometers_to_miles(kms)
    kilometers = kms.to_f
    kilometers / 1.6
  end
end
