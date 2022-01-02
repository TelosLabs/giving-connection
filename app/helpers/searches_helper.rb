# frozen_string_literal: true

module SearchesHelper
  MIN_REQUIRED_PAGES = 1

  def list_of_filters(object)
    list = []
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list << object.services&.map(&:last)&.flatten
    list << "Open Now" if object.open_now.present?
    list << "Open On Weekends" if object.open_weekends.present?
    list << "#{kilometers_to_miles(object.distance).to_i} mi" if object.distance.present?
    list.flatten.compact
  end

  def kilometers_to_miles(kms)
    kilometers = kms.to_f
    miles = kilometers / 1.6
  end
end
