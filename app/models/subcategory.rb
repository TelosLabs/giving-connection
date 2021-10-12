class Subcategory < ApplicationRecord
  belongs_to :organization
  has_one :category
end
