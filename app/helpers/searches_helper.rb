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

  def list_of_services(object)
    list = []
    list << object.services&.map(&:last)&.flatten
    list.flatten.compact
  end

  def list_of_causes(object)
    list = []
    list << object.causes&.flatten
    list.flatten.compact
  end

  def list_of_beneficiary_groups(object)
    list = []
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list.flatten.compact
  end

  def kilometers_to_miles(kms)
    kilometers = kms.to_f
    miles = kilometers / 1.6
  end

  def take_off_intersection_from_array(source_array, target_array)
    intersection = source_array.intersection(target_array)
    intersection.each { |item| target_array.delete(item) }
    target_array
  end
end
