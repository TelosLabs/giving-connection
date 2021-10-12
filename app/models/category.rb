class Category < ApplicationRecord
  belongs_to :subcategory
  has_many :subcategories
end
