module SearchesHelper
  def list_of_filters(object)
    list = []
    list << object.beneficiary_groups&.map(&:last)&.flatten
    list << object.services&.map(&:last)&.flatten
    list.flatten.compact
  end
end
