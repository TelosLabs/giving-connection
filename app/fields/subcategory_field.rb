# frozen_string_literal: true

require 'administrate/field/base'

class SubcategoryField < Administrate::Field::Base
  def to_s
    data
  end

  def self.permitted_attribute(attr, _options = nil)
    # Yes, this has to be a hash rocket `=>`,
    # not a colon `:`. Otherwise it will be the key
    # `attr` (literally) as opposed to a key whose name
    # is the value of the argument `attr`.
    { attr => [] }
  end

  def subcategory_types
    Organization::CATEGORIES_AND_SUBCATEGORIES
  end

  # def categories_formated
  #   data.first.organization.categories.map { |category| category.name }.uniq
  # end
end
