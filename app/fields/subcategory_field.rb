require "administrate/field/base"

class SubcategoryField < Administrate::Field::Base
  def to_s
    data
  end

  def subcategory_types
    Organization::CATEGORIES_AND_SUBCATEGORIES
  end
end

