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

  def selected_services_pills(object, top_10_services)
    list = []
    top_10_services = top_10_services.map(&:name)
    object.services&.map(&:last)&.flatten&.each do |service|
      list << service if top_10_services.include?(service)
    end
    selected = list.flatten.compact.join(", ")
    "Selected Pills: #{selected}" if selected.present?
  end

  def list_of_services(object, top_10_services)
    list = []
    top_10_services = top_10_services.map(&:name)
    list << object.services&.map(&:last)&.flatten
    list.flatten.compact - top_10_services
  end

  def selected_cuases_pills(object, top_10_causes)
    list = []
    top_10_causes = top_10_causes.map(&:name)
    object.causes&.flatten&.each do |cause|
      list << cause if top_10_causes.include?(cause)
    end
    selected = list.flatten.compact.join(", ")
    "Selected Pills: #{selected}" if selected.present?
  end

  def list_of_causes(object, top_10_causes)
    list = []
    top_10_causes = top_10_causes.map(&:name)
    list << object.causes&.flatten
    list.flatten.compact - top_10_causes
  end

  def selected_beneficiary_groups_pills(object, top_10_beneficiary_groups)
    list = []
    top_10_beneficiary_groups = top_10_beneficiary_groups.map(&:name)
    object.beneficiary_groups&.map(&:last)&.flatten&.each do |beneficiary_group|
      list << beneficiary_group if top_10_beneficiary_groups.include?(beneficiary_group)
    end
    selected = list.flatten.compact.join(", ")
    "Selected Pills: #{selected}" if selected.present?
  end

  def list_of_beneficiary_groups(object, top_10_beneficiary_groups)
    list = []
    top_10_beneficiary_groups = top_10_beneficiary_groups.map(&:name)
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list.flatten.compact - top_10_beneficiary_groups
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
